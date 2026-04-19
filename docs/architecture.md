# Architecture of FlutterFire for Tizen

## Goals

1. Keep a single native `.so` footprint at zero — every Firebase plugin here is
   pure Dart. Adding another Firebase plugin to an app must not inflate the
   final `.tpk`.
2. Remain a conforming non-endorsed federated implementation of each FlutterFire
   plugin. Application code continues to depend on the upstream packages
   (`firebase_core`, `firebase_auth`, …) unchanged.
3. Be mergeable into `flutter-tizen/plugins` without structural deviation — the
   layout, linting, and CI contract mirror that repository.

## Why pure Dart

The previous C++ implementation shipped `libfirebase_app.so`, the per-service
library (`libfirebase_database.so`, `libfirebase_storage.so`, …), and a host of
shared helpers inside every plugin. Two concrete problems:

- The prebuilt Firebase C++ binaries were fetched from personal GitHub accounts
  (`hs0225/download`, `daeye0n/gooddaytocode`) at build time. That is a
  supply-chain hazard and is unacceptable for a flutter-tizen/plugins PR.
- `libfirebase_app.so` was linked into every plugin, so an app that used the
  four plugins paid for four copies. Common helpers under `dep/` were duplicated
  verbatim between plugins.

Both disappear with a Dart-only design.

## Transport layer

| Package                              | Backend                                                                 |
|--------------------------------------|-------------------------------------------------------------------------|
| `firebase_core_tizen`                | `firebase_dart` app registry + shared `TizenAuthContext` + path_provider |
| `firebase_auth_tizen`                | `firebase_dart` auth                                                    |
| `firebase_database_tizen`            | `firebase_dart` Realtime Database                                       |
| `firebase_storage_tizen`             | Direct REST over `package:http` (streaming upload/download)             |
| `cloud_functions_tizen`              | Direct callable HTTPS (gen1 + gen2)                                     |
| `firebase_app_installations_tizen`   | Direct Installations REST                                               |
| `firebase_remote_config_tizen`       | Direct Remote Config REST with Installations token + ETag cache         |
| `firebase_ai_tizen`                  | Direct HTTPS to `generativelanguage.googleapis.com`                     |

Why not route everything through `firebase_dart`:

- Its Storage implementation has unresolved upstream bugs (putData, listAll);
  we replace it with a thin REST client.
- It does not ship Cloud Functions, Installations, Remote Config, or Firebase AI
  clients.

## Shared runtime

`firebase_core_tizen` is the only package that owns Firebase state. It exports
a small "internal" surface — `TizenFirebaseRegistry`, `TizenAuthContext`,
`TizenHttpClient` — that the other plugins depend on. This keeps the token
refresh loop, Hive persistence, and HTTP client singleton in one place.

The runtime is initialised once per process via a `Lock`-guarded
`FirebaseDart.setup(isolated: true, …)` call. Persistence uses
`path_provider`'s application-support directory, inside the app's Tizen
sandbox. **Hive is currently opened without an encryption cipher** — ID and
refresh tokens therefore live as plaintext under the app-specific data
path. This is contained by Tizen's app-sandboxing model (no other app on a
stock Tizen TV can read that directory), but a privileged/attacker-rooted
device can dump the box. We track encrypted persistence as a follow-up
task; until it lands, consumers that worry about stolen devices should sign
out on app suspend.

## Auth token sharing

`TizenAuthContext` tracks the currently signed-in user and caches the ID token.
It exposes `Future<String?> getIdToken({bool forceRefresh})` with singleflight
so that a burst of Storage / Functions / Remote Config calls triggers exactly
one network refresh. When a remote 401 is received, the caller forces a single
refresh and retries. Per-package refresh timers are forbidden — they caused
token races in the previous design.

## Unsupported features

Every unsupported method throws `UnimplementedError` with a concrete reason —
we never silently no-op.

Examples:
- OAuth popup/redirect sign-in (no browser redirect handler usable from a TV
  app).
- Phone auth (no reCAPTCHA verifier on Tizen).
- Storage / Auth / Functions / Database emulator endpoints (undefined cert
  behaviour on TV; easy to re-enable once we have a device test story).
- Realtime Config live updates (`onConfigUpdated`) — the streaming endpoint is
  not cheap to emulate on a TV with aggressive standby.

## Packaging discipline

- No `dependency_overrides` in any published `pubspec.yaml`. Local development
  overrides live in `pubspec_overrides.yaml` (gitignored).
- All federated packages pin the **same** upstream Firebase set
  (`firebase_core ^4.7.0`, `firebase_core_platform_interface ^6.0.3`, and
  version-matched plugin platform interfaces).
- Each package carries its own `LICENSE`, `CHANGELOG.md`, and README shaped
  like other flutter-tizen/plugins packages.

## Tizen-specific notes

- Example apps require `http://tizen.org/privilege/internet`. The manifest is
  authoritative — if it is missing the privilege, nothing will reach Firebase
  even with correct code.
- Target profile is `common-6.0` (API level 6.0). Tizen 6.0+ TVs and emulators
  are supported.
- All Hive, WebSocket, and streaming I/O happen inside the `firebase_dart`
  isolate, so the Flutter UI thread is never blocked by network traffic.
