# Flutter Tizen Firebase Migration Plan

## Why the Architecture Changed

The original repository used Firebase C++ SDK builds and shipped per-plugin `.so` files. That model is expensive on Tizen because each additional Firebase package tends to increase:

- bundled native binaries
- build integration complexity
- package size
- maintenance burden when upstream SDKs change

For long-term maintenance inside `flutter-tizen/plugins`, the better fit is a pure Dart federated plugin design.

## Chosen Runtime Strategy

### Shared runtime

- `firebase_core_tizen` initializes a single `firebase_dart` runtime using Tizen application support storage.
- Other Tizen Firebase packages resolve the already-initialized Dart Firebase app from `firebase_core_tizen`.

### Package backends

| Package | Backend strategy |
| --- | --- |
| `firebase_core_tizen` | `firebase_dart` app/bootstrap layer |
| `firebase_auth_tizen` | `firebase_dart` auth |
| `firebase_database_tizen` | `firebase_dart` realtime database |
| `firebase_storage_tizen` | `firebase_dart` storage |
| `cloud_functions_tizen` | direct callable HTTPS protocol |

### Why Cloud Functions is different

`firebase_dart` does not currently provide a Cloud Functions client. For that package, the Tizen adapter uses the callable HTTPS protocol directly and forwards the current Firebase Auth ID token when available.

## Package Layout for `flutter-tizen/plugins`

Each package should follow the normal Tizen pure Dart plugin pattern:

- package lives in `packages/<plugin_name>/`
- `pubspec.yaml` uses `flutter.plugin.platforms.tizen.dartPluginClass`
- no bundled Firebase native shared libraries
- examples depend on the local Tizen federated packages through path overrides during development

## Current Implementation Notes

### Implemented

- `firebase_core_tizen`
- `firebase_auth_tizen`
- `firebase_database_tizen`
- `firebase_storage_tizen`
- `cloud_functions_tizen`

### Partially implemented or intentionally deferred

- `firebase_auth_tizen`
  - no popup or redirect OAuth flow
  - no phone verification flow
  - no auth emulator
- `cloud_functions_tizen`
  - no callable streaming API yet
- `firebase_storage_tizen`
  - no storage emulator
  - download tasks use a simplified one-shot implementation
- `firebase_database_tizen`
  - cursor parity is close but not exact for every query helper

## Candidate Next Packages

### Good next target

- Remote Config
  - likely feasible with a small REST-backed adapter
  - should be scoped carefully because fetch/activate semantics need FlutterFire-compatible caching behavior

### Needs a separate design

- Firestore
  - possible only if API parity, offline semantics, and listener behavior are narrowed first
  - should not be started as a quick wrapper

### Not recommended for the current migration phase

- Messaging
- Analytics
- Crashlytics
- Performance
- App Check

These products depend on platform-native integrations, device services, or attestation/reporting flows that do not map cleanly to Tizen through the current pure Dart approach.

## Integration Steps

1. Move these packages into `flutter-tizen/plugins/packages/`.
2. Replace the existing `firebase_core_tizen` implementation there with the shared `firebase_dart` runtime bootstrap used here.
3. Add CI jobs for `flutter pub get`, `dart analyze`, and example smoke coverage.
4. Decide package-by-package endorsement and publishing order after API parity review.
