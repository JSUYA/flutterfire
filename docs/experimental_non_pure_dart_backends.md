# Experimental Non-Pure-Dart Firebase Backends for Tizen

This repository now contains three side-by-side backend experiments for Tizen that intentionally avoid the default pure Dart runtime.

## Why these experiments exist

The original Tizen Firebase work relied on cross-compiled Firebase C++ shared libraries copied into each plugin. That solved the immediate platform gap, but it also caused binary duplication and a large maintenance surface.

The current pure Dart path is smaller and easier to integrate with `flutter-tizen/plugins`, but it is not the only architecture worth evaluating. These experiments exist to compare the main non-pure-Dart alternatives with running code.

## 1. Shared C++ runtime host

Location:

- `experimental/native/src/firebase_runtime_host.cpp`
- `experimental/packages/firebase_cpp_shared_runtime_backend`

Design:

- a single long-lived native host process owns backend state
- auth state is stored in the native runtime once
- Dart wrappers talk to that runtime over a simple tab-separated protocol

Why it matters:

- this is the closest replacement for the previous per-plugin C++ `.so` design
- it removes per-package duplication by centralizing the native runtime
- it gives a path to swap the internal HTTP implementation for Firebase C++ SDK calls later

Current implemented scope:

- initialize
- email/password sign-in
- callable Functions requests with shared auth token forwarding

## 2. One-shot native protocol core

Location:

- `experimental/native/src/firebase_rest_cli.cpp`
- `experimental/packages/firebase_native_protocol_backend`

Design:

- each Dart operation invokes a native CLI once
- the native binary performs direct HTTP protocol calls
- Dart keeps temporary auth state between calls

Why it matters:

- much simpler than a long-lived runtime host
- easier to debug and sandbox
- suitable when code size and state sharing are less important than isolation

Current implemented scope:

- initialize
- email/password sign-in
- callable Functions requests

## 3. WebView JavaScript bridge

Location:

- `experimental/packages/firebase_webview_bridge_backend`

Design:

- a browser context loads the Firebase JavaScript SDK
- Dart/native code sends commands through a bridge
- the JavaScript side uses the web Firebase client directly

Why it matters:

- this is the most natural option if Tizen WebView or hybrid apps are acceptable
- it keeps client semantics closer to official Firebase Web behavior
- it is the best fit for OAuth-heavy flows, as long as the browser environment is acceptable

Current implemented scope:

- initialize
- email/password sign-in
- callable Functions requests

## How to verify locally

1. Build the native binaries:

```sh
cmake -S experimental/native -B experimental/native/build
cmake --build experimental/native/build
```

2. Run package analysis:

```sh
cd experimental/packages/firebase_backend_contract && dart analyze
cd ../firebase_cpp_shared_runtime_backend && dart analyze
cd ../firebase_native_protocol_backend && dart analyze
cd ../firebase_webview_bridge_backend && dart analyze
```

3. Run tests:

```sh
cd experimental/packages/firebase_cpp_shared_runtime_backend && dart test
cd ../firebase_native_protocol_backend && dart test
cd ../firebase_webview_bridge_backend && dart test
```

## What these experiments are and are not

These are real running implementations, not mock diagrams. However, they are intentionally scoped experiments and not drop-in replacements for the full FlutterFire surface yet.

The implemented slice is enough to evaluate:

- packaging shape
- runtime ownership
- auth token flow
- callable request routing
- local testability

The next practical expansion target for all three paths would be Realtime Database listeners.
