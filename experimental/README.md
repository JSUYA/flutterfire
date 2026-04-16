# Experimental Non-Pure-Dart Backends

This directory contains three concrete backend experiments for Tizen that do not rely on the repository's default pure Dart runtime.

## Included experiments

- `native/`
  - shared C++ HTTP core used by the experiments below
- `packages/firebase_cpp_shared_runtime_backend`
  - a long-lived native runtime host process that keeps Firebase auth state once and serves multiple package calls
- `packages/firebase_native_protocol_backend`
  - a one-shot native CLI that talks to Firebase protocols directly for each operation
- `packages/firebase_webview_bridge_backend`
  - a WebView-oriented JavaScript bridge that can load the Firebase JS SDK inside a browser context

## Implemented scope

Each backend implements the same minimal product slice:

- initialize backend configuration
- sign in with email and password
- call a callable Cloud Function

That scope is intentionally small enough to verify all three architectures, while still matching real Firebase product behavior.

## Verification

- native C++ binaries build through CMake
- Dart wrappers pass `dart analyze`
- shared runtime and one-shot protocol backends pass integration-style tests against a local fake Firebase server
- the WebView bridge passes Dart-side tests and a Node.js run of the JavaScript bridge core
