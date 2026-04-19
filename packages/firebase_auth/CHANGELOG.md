## 0.1.0-dev.1

Status: **work in progress — does not yet compile cleanly against
`firebase_auth_platform_interface 8.1.9`**. See `docs/review_audit.md` for
the full list of open parity items. The package is versioned `0.1.0-dev.1`
so it cannot be accidentally pulled into a production app.

Known parity gaps (blocked on pigeon-generated types):

* `UserTizen` super call passes a raw `Map<String, Object?>` where upstream
  8.1.9 now expects `PigeonUserDetails`.
* `getIdTokenResult` throws `UnimplementedError` — we need to produce a
  `PigeonIdTokenResult` instead of constructing `IdTokenResult` from a Map.
* `checkActionCode` throws — upstream `ActionCodeInfo` now accepts an
  `ActionCodeInfoOperation` enum + `ActionCodeInfoData` object.
* `_wrapCredential` throws — `UserCredentialPlatform` is now an abstract
  class; Tizen needs a concrete subclass built against
  `PigeonUserCredential`.

What is in place and ready to be tested once the pigeon refactor lands:

* `firebase_dart` auth backend wiring.
* Token bridge into `TizenAuthContext`.
* `authStateChanges` / `idTokenChanges` / `userChanges` stream plumbing.
* Identity Toolkit error-code mapping table (35+ codes).
* Email-link / phone / MFA / emulator / OAuth popup APIs all throw
  `UnimplementedError` with a concrete reason — no silent no-ops.

## 0.1.0 (not released)

* First draft of the Tizen implementation — superseded by 0.1.0-dev.1
  after the code-level parity audit.
