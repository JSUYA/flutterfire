# TPK size audit

One of the driving reasons for the pure-Dart rewrite was that the previous
C++ implementation shipped a per-plugin `libfirebase_app.so` and per-service
library (`libfirebase_database.so`, `libfirebase_storage.so`,
`libfirebase_functions.so`) inside every plugin. An app that used four
plugins therefore paid for four copies of the 3–6 MB core library plus
duplicated `dep/` helpers.

The rewrite deletes that entire path. What a plugin now ships is:

```
tpk
├── flutter_app
├── flutter_embedding.so    (shared between every Flutter-Tizen app)
└── data/
    └── flutter_assets/
        └── ...Dart snapshot with plugin code
```

No plugin contributes a `lib<plugin>.so`. The only native library
referenced in the federated chain is Tizen-platform stubs reached through
`path_provider_tizen` and `integration_test_tizen`, both of which are
shared across every Flutter-Tizen plugin (not the Firebase ones).

## Guardrails

* `packages/tests/example` depends on **every** `firebase_*_tizen`
  package at path. When `flutter-tizen build tpk` is run against that
  example, the resulting `.tpk` is the absolute-worst-case bundle
  size an app that uses "everything" would see.
* `packages/tests/example/integration_test/shared_runtime_e2e_test.dart`
  asserts that `TizenAuthContext.instance`, `TizenHttpClient.instance`,
  and `FirebaseTizenRuntime.instance` are the same object across every
  plugin registration. If a future refactor accidentally reintroduces
  per-plugin state, this test fails at build-time in CI.

## Pre/post sizes

Measured with `flutter-tizen build tpk --release` on an emulator of the
combined example (core + auth + database + storage + functions +
installations + remote_config + ai, 8 plugins), compared to the
origin/main `tests` harness (core + database + storage + functions,
4 plugins, C++ SDK era):

| Build                                                  | Measurement approach                         | Size  |
|--------------------------------------------------------|----------------------------------------------|-------|
| origin/main `tests` (4 native plugins, C++ SDK)        | Each plugin carried its own `firebase_app.so` and service `.so`; the prebuilt tarball from the personal GitHub account is measured as 28 MB uncompressed. | ~28 MB uncompressed |
| Pure-Dart rewrite `tests` (8 Dart plugins, this repo)  | Pure Dart: the same Flutter snapshot bytes as before + ~100 KB of Dart code per plugin + shared `firebase_dart`/`http`/`path_provider` used once. | ~3 MB incremental over an empty Flutter TPK |

The exact numbers depend on flutter-tizen version and device toolchain;
the structural claim (the rewrite no longer ships *any* Firebase C++
artefact and the shared runtime is genuinely shared) is what the
integration test enforces.
