# firebase_storage_tizen

The Tizen implementation of [`firebase_storage`](https://pub.dev/packages/firebase_storage).

This package uses the pure Dart [`firebase_dart`](https://pub.dev/packages/firebase_dart) runtime instead of bundled Firebase C++ shared libraries.

## Usage

```yaml
dependencies:
  firebase_core: ^4.7.0
  firebase_core_tizen: ^0.2.0
  firebase_storage: ^13.3.0
  firebase_storage_tizen: ^0.2.0
```

## Required privilege

```xml
<privileges>
  <privilege>http://tizen.org/privilege/internet</privilege>
</privileges>
```

## Limitations

- the storage emulator is not implemented
- download tasks are implemented as a one-shot file write flow
- `putBlob()` is intentionally unavailable on native platforms
