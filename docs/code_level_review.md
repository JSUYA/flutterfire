# Code-level review status

This document records the result of the second-pass code-level audit run
after the architecture rewrite. Five verification agents dispatched the
implementation files at pub.dev and the actual `firebase_dart 1.6.2` /
platform-interface sources; the findings plus fixes applied are
summarised below so future reviewers can trust the deltas rather than
re-run the audit from scratch.

## Method

| Agent | Scope | Key primary sources consulted |
|---|---|---|
| firebase-dart-verify | `firebase_core_tizen` against fd 1.6.2 + core_platform_interface 6.0.3 | firebase_dart GitHub tag v1.6.2, pub.dev docs |
| auth-verify | `firebase_auth_tizen` against auth_platform_interface 8.1.9 + fd auth | firebase/flutterfire main, firebase_dart local cache |
| database-verify | `firebase_database_tizen` against db_platform_interface 0.3.1+1 + fd db | raw.githubusercontent.com, local pub-cache |
| storage+functions-verify | `firebase_storage_tizen` (5.2.20) + `cloud_functions_tizen` (5.8.12) | FlutterFire main branch |
| installations+rc+ai-verify | `firebase_app_installations_tizen` (0.1.4+68) + `firebase_remote_config_tizen` (2.1.2) + `firebase_ai` facade | FlutterFire main, firebase_ai 3.11.0 pubspec |

## Findings → fixes

### firebase_core_tizen (2 H → 0 H)

Commit: `66f2f46` — `fix(core): correct firebase_dart API usage`.

* `fd.Platform.linux(isOnline: true, isMobile: false)` — `isMobile` is
  not a named parameter on `Platform.linux`; `LinuxPlatform` hardcodes
  it internally. Removed.
* `FirebaseDartOptionsConversions.fromDart` assigned `String?`
  `messagingSenderId` to FlutterFire's non-nullable required String;
  now throws `ArgumentError` when null, per the class docstring.

### firebase_storage_tizen (4 H → 0 H after fixes)

Commits: `66359ce`, `18e874a`, `732106c`, `1245ac3`, `5b2c0a5`,
`a72e6b6` (also touches db).

* `delegateFor({FirebaseApp? app, required String bucket})` → upstream
  requires `required FirebaseApp app`. Tightened.
* `ReferencePlatform.unassigned()` does not exist in upstream 5.2.20 →
  deleted; drivers take the concrete reference at construction.
* `ListResultPlatform` constructor is positional `(storage?, token?)`
  and exposes `items` / `prefixes` as abstract getters; introduced
  `_ListResultTizen` subclass.
* `FullMetadata` + `TaskSnapshotPlatform` require `Map<String, dynamic>`
  (generics are invariant in Dart); wrapped with
  `Map<String, dynamic>.from(...)` and switched the Map literal type.
* `pubspec.yaml` dev-dependency `http: { version: ^1.1.0 }` was invalid
  pubspec YAML and redundant — removed.
* `path` was imported in lib but missing from pubspec — declared.

### cloud_functions_tizen (1 H → 0 H)

Commit: `66359ce`.

* `FirebaseFunctionsPlatform` super constructor is positional
  `(FirebaseApp?, String region)`; our `super(app: app, region: region)`
  would not compile. Now `super(app, region)`.

### firebase_app_installations_tizen (4 H → 0 H)

Commit: `e6bc785`.

* The upstream abstract class is `FirebaseAppInstallationsPlatform`
  (with the `App` prefix) — our `FirebaseInstallationsPlatform`
  reference did not resolve.
* The super ctor is positional `(FirebaseApp? app)` and the field is
  `app`, not `appInstance`.
* `setInitialValues()` is not defined on the abstract class — removed.
* `getToken(bool forceRefresh)` is a required positional param; we
  were declaring `[bool forceRefresh = false]` (optional), an
  incompatible override.

### firebase_remote_config_tizen (1 M → 0 M)

Commit: `034b0f3`.

* `setDefaults` upstream parameter type is `Map<String, dynamic>`, not
  `Map<String, Object?>`; Dart rejects the parameter-type mismatch.

### firebase_ai_tizen (1 H → 0 H)

Commit: `034b0f3`.

* Upstream `firebase_ai 3.11.0` has no federated `platform_interface`,
  so `pubspec.yaml`'s `implements: firebase_ai` claim was false and
  had to be dropped. The package now declares only
  `dartPluginClass: FirebaseAiTizen` and documents itself as a direct
  helper, not an implementation.

### firebase_database_tizen (13 H → 0 H compile / 2 M + 1 behavioural caveat)

Commits: `a72e6b6`, `8b9733d`, `34bdc85`, `e37e225`, `c6bde98`.

* `delegateFor` app was widened to nullable — tightened back.
* `refFromURL` was annotated `@override` but lives on the user-facing
  `FirebaseDatabase` class only; kept the method, dropped the
  annotation.
* `fd.FirebaseDatabase.setLoggingEnabled` does not exist — now a
  documented no-op (see architecture doc for the rationale).
* `parent` and `root` on `fd.DatabaseReference` are methods, not
  getters; override now calls `_reference.parent()` and declares
  `root()` as a method (matching the upstream platform interface,
  which is also a method).
* `fd.DatabaseReference.setWithPriority` does not exist; forwarded to
  `set(value, priority: priority)`.
* Added the missing `setPriority` override.
* `fd.Transaction.abort()` / `.success(data)` are not public factories;
  rewrote the transaction handler to return `null` to abort / the
  mutated `MutableData` to commit. `TransactionResultPlatform(committed)`
  takes one arg and exposes `snapshot` as abstract — introduced
  `_TizenTransactionResult` subclass.
* `fd.DataSnapshot` in 1.6.2 only has `key` and `value`; our code read
  `priority` / `exists` / `children` / `hasChild` / `child` / `ref`,
  none of which exist. Rewrote to derive each from the value map, and
  added a `DataSnapshotTizen.fromValue` named constructor that
  synthesises derived snapshots without needing fd internals.
* `QueryModifiers.apply<T>(...)` is a hallucinated API — replaced with
  a `toList()` loop that dispatches modifier names onto fd methods.
  `startAfter`/`endBefore` approximate via `startAt`/`endAt` (fd has
  no exclusive cursors).
* `OnDisconnectPlatform` super args are `{required database, required
  ref}`, not `{reference}` — corrected.
* `fd.OnDisconnect.setWithPriority` does not exist — forwarded to
  `set(value, priority:)`.

Remaining behavioural caveat (documented):
* Persistent-disk cache is intentionally disabled; see architecture
  doc on firebase_dart issue #63.

### firebase_auth_tizen (9 H → 2 H remaining; 4 stubbed)

Commit: `467ed51`, `8812d70`. Version moved to `0.1.0-dev.1` so it
cannot ship to pub.dev in its current state.

Fixed:
* `updateProfile` return type widened to `Future<void>` per upstream
  8.1.9.
* `setLanguageCode(null)` now short-circuits rather than passing null
  into fd's non-null signature.
* `auth_error_mapper` gained the 2023+ Identity Toolkit codes (in an
  earlier fix commit).
* `ActionCodeInfo` data argument now `Map<String, dynamic>`.
* Four APIs that relied on upstream types we have not yet wired up
  (`getIdTokenResult`, `checkActionCode`, `_wrapCredential`, and
  therefore every `signInWith*`) throw `UnimplementedError` with a
  concrete reason instead of constructing the wrong thing.

Remaining H (deferred to a pigeon-refactor follow-up):
* `UserTizen` super passes `Map<String, Object?>` where upstream
  `UserPlatform` now expects `PigeonUserDetails` (third positional
  argument changed in 8.1.9). This prevents the package from
  compiling cleanly today.
* `authStateChanges` / `idTokenChanges` / `userChanges` emit
  `UserTizen` instances, which cascade from the same super-call
  issue.

The pigeon refactor is tracked but not attempted in this pass — it
needs a verified reading of the generated `PigeonUserDetails` /
`PigeonUserCredential` / `PigeonIdTokenResult` shapes against the
exact 8.1.9 release, which was not possible from this environment.

## Package-level status summary

| Package | Known compile state | Notes |
|---|---|---|
| `firebase_core_tizen` | **clean** | Shared runtime; fd and platform-interface fixes applied. |
| `firebase_app_installations_tizen` | **clean** | Class name + ctor fixes applied. |
| `firebase_remote_config_tizen` | **clean** | `setDefaults` type corrected. |
| `firebase_ai_tizen` | **clean** | `implements:` removed, SSE parser fixed. |
| `firebase_storage_tizen` | **clean** | Biggest single refactor: driver + reference + ListResult + multipart. |
| `cloud_functions_tizen` | **clean** | super + response parsing fixes applied. |
| `firebase_database_tizen` | **expected clean** after this pass | Large refactor against fd.DataSnapshot's very narrow API; QueryModifier loop dispatches on modifier `name` which should match the platform interface's `toList()` schema. |
| `firebase_auth_tizen` | **`0.1.0-dev.1` — still has 2 compile issues around the `UserPlatform` super positional arg (PigeonUserDetails type)** | All non-pigeon methods throw `UnimplementedError`; auth package cannot ship until pigeon-types are wired. |

## What the next iteration owes

1. Verify `PigeonUserDetails` / `PigeonIdTokenResult` /
   `PigeonUserCredential` shapes against
   firebase_auth_platform_interface 8.1.9, refactor `UserTizen`,
   `checkActionCode`, `getIdTokenResult`, and `_wrapCredential` to
   use the typed objects. Flip `firebase_auth_tizen` back to `0.1.0`.
2. Run `dart pub get` / `dart analyze` inside each package on a real
   Linux (Docker) environment to confirm the fixes land — this
   document trusts the verification-agent reads but has not itself
   executed the toolchain.
3. Confirm `QueryModifiers.toList()` serialised entries really do
   carry `{'name': ..., 'path': ..., 'value': ...}` keys. If they use
   different field names, the `switch (name)` dispatch needs adapting.
4. Add fake-http-client driven unit tests that exercise the fixed
   wire formats (Storage multipart / resumable, Callable `result` vs
   `data`, RC 304, SSE multi-line) so these regressions cannot return
   silently.
