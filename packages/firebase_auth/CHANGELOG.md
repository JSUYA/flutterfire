## 0.1.0

* Initial release: Tizen implementation of `firebase_auth`, backed by the
  `firebase_dart` auth runtime owned by `firebase_core_tizen`.
* Supports email/password sign-in and sign-up, anonymous sign-in, custom
  token sign-in, password reset (send / confirm / verify), email
  verification, profile update, email/password update, `reload`, account
  deletion, `checkActionCode`, and `getIdTokenResult`.
* Emits `authStateChanges`, `idTokenChanges`, and `userChanges` as broadcast
  streams, mirrored into the shared `TizenAuthContext` so sibling plugins
  (Storage, Functions, Remote Config) pick up the same ID token.
* Errors are mapped to `FirebaseAuthException` with the canonical upstream
  codes (`user-not-found`, `wrong-password`, `email-already-in-use`,
  `invalid-credential`, …). 35+ identity-toolkit codes are covered,
  including the 2023+ `INVALID_LOGIN_CREDENTIALS` combined code.
* Wraps firebase_dart's `User` into a `UserTizen` that passes a proper
  `PigeonUserDetails` to the upstream `UserPlatform` constructor, and
  returns sign-in results through a concrete `UserCredentialTizen`
  subclass of `UserCredentialPlatform`.
* Intentionally unsupported — throw `UnimplementedError` with a reason
  string: OAuth popup/redirect sign-in, phone auth + MFA, Auth emulator,
  email-link sign-in, Game Center, `linkWithCredential` /
  `reauthenticateWithCredential` for OAuth providers, and
  `updatePhoneNumber`.
