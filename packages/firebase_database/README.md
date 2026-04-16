# firebase_database_tizen

The Tizen implementation of [`firebase_database`](https://pub.dev/packages/firebase_database).

This package uses the pure Dart [`firebase_dart`](https://pub.dev/packages/firebase_dart) runtime instead of bundled Firebase C++ libraries.

## Usage

```yaml
dependencies:
  firebase_core: ^4.7.0
  firebase_core_tizen: ^0.2.0
  firebase_database: ^12.0.4
  firebase_database_tizen: ^0.2.0
```

## Required privilege

```xml
<privileges>
  <privilege>http://tizen.org/privilege/internet</privilege>
</privileges>
```

## Limitations

- emulator support is implemented through database URL rewriting and should be treated as development-only
- `startAfter` and `endBefore` are approximated using the closest available query operations
