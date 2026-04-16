# firebase_auth_tizen

The Tizen implementation of [`firebase_auth`](https://pub.dev/packages/firebase_auth).

## Status

This package uses the pure Dart [`firebase_dart`](https://pub.dev/packages/firebase_dart)
runtime instead of bundling native Firebase C++ shared libraries.

Currently supported:

- Firebase app instance binding through `firebase_core_tizen`
- Anonymous sign-in
- Email/password sign-in and account creation
- Email link sign-in helpers
- Custom token sign-in
- Credential-based sign-in for email/OAuth credentials
- User reload, delete, unlink, update email/password/profile
- Auth state, ID token, and user change streams

Currently not supported on Tizen:

- Popup/redirect based social sign-in flows
- Phone number verification flows
- Auth emulator integration
- Persistence mode switching

## Usage

Add both `firebase_auth` and `firebase_auth_tizen` to your app:

```yaml
dependencies:
  firebase_core: ^4.2.0
  firebase_core_tizen: ^0.2.0
  firebase_auth: ^6.1.1
  firebase_auth_tizen: ^0.1.0
```
