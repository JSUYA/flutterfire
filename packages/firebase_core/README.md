# firebase_core_tizen

The Tizen implementation of [`firebase_core`](https://pub.dev/packages/firebase_core).

This package now uses the pure Dart [`firebase_dart`](https://pub.dev/packages/firebase_dart) runtime instead of bundling Firebase C++ shared libraries.

## Usage

```yaml
dependencies:
  firebase_core: ^4.7.0
  firebase_core_tizen: ^0.2.0
```

Then initialize Firebase as usual:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Notes

- Tizen does not read Firebase options from native resources automatically.
- App options must be provided from Dart.
- Automatic data collection and automatic resource management remain no-op style behaviors on Tizen.
