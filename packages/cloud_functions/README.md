# cloud_functions_tizen

The Tizen implementation of [`cloud_functions`](https://pub.dev/packages/cloud_functions).

This package uses the Firebase callable HTTPS protocol directly instead of bundling Firebase C++ shared libraries.

## Usage

```yaml
dependencies:
  firebase_core: ^4.7.0
  firebase_core_tizen: ^0.2.0
  cloud_functions: ^6.2.0
  cloud_functions_tizen: ^0.2.0
```

## Supported

- regional callable functions
- callable functions created from a URI
- auth token forwarding when a Firebase Auth user is signed in
- callable error mapping for standard backend statuses

## Limitations

- streaming callable APIs are not implemented
- emulator routing is not implemented separately from custom origins
