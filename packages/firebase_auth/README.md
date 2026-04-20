# firebase_auth_tizen

[![pub package](https://img.shields.io/pub/v/firebase_auth_tizen.svg)](https://pub.dev/packages/firebase_auth_tizen)

The Tizen implementation of [`firebase_auth`](https://pub.dev/packages/firebase_auth).

This is a [non-endorsed federated implementation][federated]: add it alongside
`firebase_auth` and `firebase_core_tizen` in your app.

## Required privileges

```xml
<privileges>
  <privilege>http://tizen.org/privilege/internet</privilege>
</privileges>
```

## Usage

```yaml
dependencies:
  firebase_auth: ^6.4.0
  firebase_auth_tizen: ^0.1.0
  firebase_core: ^4.7.0
  firebase_core_tizen: ^2.0.0
```

Then use the upstream API unchanged:

```dart
import 'package:firebase_auth/firebase_auth.dart';

final UserCredential credential =
    await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'tizen@example.com',
  password: 'correct-horse-battery',
);
```

## Supported devices

| Tizen version | TV | TV emulator |
|:-------------:|:--:|:-----------:|
| 6.0 and above | ✔️  | ✔️           |

## Limitations

The following APIs throw `UnimplementedError` with a concrete reason rather
than silently returning:

* OAuth popup / redirect sign-in (no redirect handler usable from a TV app).
  For social sign-in on TV, mint a custom token from your backend after the
  user authenticates on a companion device and call `signInWithCustomToken`.
* Phone auth (`verifyPhoneNumber`, `updatePhoneNumber`), MFA, and Auth
  emulator — Tizen has no SMS retrieval API and no reCAPTCHA verifier.
* `linkWithCredential` / `reauthenticateWithCredential` for OAuth credentials.
* Game Center, provider-specific `customParameters`, `setPersistence`.

## Design

`FirebaseAuthTizen` delegates to the `firebase_dart` auth runtime owned by
`firebase_core_tizen`. `FirebaseAuthTizen.register()` registers itself against
[`TizenAuthContext`](../firebase_core/lib/src/tizen_auth_context.dart), so
Storage, Cloud Functions, and Remote Config read a single, always-fresh ID
token instead of spinning per-package refresh timers.

## Package structure

* `lib/firebase_auth_tizen.dart`: public entrypoint that registers the Tizen federated implementation.
* `lib/src/firebase_auth_tizen.dart`: `FirebaseAuthPlatform` bridge backed by `firebase_dart`.
* `lib/src/user_tizen.dart`: upstream-shaped `UserPlatform` wrapper.
* `lib/src/pigeon_mapper.dart`: translation layer between upstream pigeon types and `firebase_dart` values.
* `lib/src/multi_factor.dart`, `action_code_settings.dart`, related helpers: explicit unsupported-surface handling.

## Flow chart

```mermaid
flowchart TD
  A[App calls FirebaseAuth API] --> B[FirebaseAuthTizen]
  B --> C[Resolve Firebase app via firebase_core_tizen]
  C --> D[Delegate auth call to firebase_dart]
  D --> E[Map firebase_dart result into upstream platform classes]
  E --> F[Update TizenAuthContext current user and ID token]
  F --> G[Return FirebaseAuth/User/UserCredential to Flutter app]
```

## Architecture chart

```mermaid
graph LR
  App[Flutter app]
  AuthPkg[firebase_auth_tizen]
  Mapper[AuthPigeonMapper]
  FD[firebase_dart auth]
  Core[firebase_core_tizen]
  AuthCtx[TizenAuthContext]
  RestPkgs[storage/functions/remote_config]

  App --> AuthPkg
  AuthPkg --> Core
  AuthPkg --> FD
  AuthPkg --> Mapper
  AuthPkg --> AuthCtx
  RestPkgs --> AuthCtx
```

[federated]: https://docs.flutter.dev/packages-and-plugins/developing-packages#non-endorsed-federated-plugin
