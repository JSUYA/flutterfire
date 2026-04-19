# FlutterFire for Tizen

FlutterFire for Tizen is a set of [non-endorsed federated][federated]
implementations of [FlutterFire][] plugins for the Tizen platform. Each plugin
is implemented in pure Dart — Firebase services are accessed either through the
[`firebase_dart`][firebase_dart] community runtime (for Core, Auth, Realtime
Database) or through the documented Firebase REST APIs directly (for Storage,
Cloud Functions, App Installations, Remote Config, and Firebase AI).

No Firebase C++ SDK binaries are bundled. The previous native implementation
that shipped per-plugin `.so` files was removed in favour of a pure-Dart stack
so that adding another Firebase plugin no longer inflates the final `.tpk`.

## Published plugins

| Plugin                               | pub.dev                                                                                                                       | Product                                                          |
|--------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| [`firebase_core_tizen`][p_core]      | [![pub package](https://img.shields.io/pub/v/firebase_core_tizen.svg)](https://pub.dev/packages/firebase_core_tizen)           | [Core](https://firebase.google.com)                              |
| [`firebase_auth_tizen`][p_auth]      | [![pub package](https://img.shields.io/pub/v/firebase_auth_tizen.svg)](https://pub.dev/packages/firebase_auth_tizen)           | [Authentication](https://firebase.google.com/products/auth)      |
| [`firebase_database_tizen`][p_db]    | [![pub package](https://img.shields.io/pub/v/firebase_database_tizen.svg)](https://pub.dev/packages/firebase_database_tizen)   | [Realtime Database](https://firebase.google.com/products/database) |
| [`firebase_storage_tizen`][p_stg]    | [![pub package](https://img.shields.io/pub/v/firebase_storage_tizen.svg)](https://pub.dev/packages/firebase_storage_tizen)     | [Cloud Storage](https://firebase.google.com/products/storage)    |
| [`cloud_functions_tizen`][p_fn]      | [![pub package](https://img.shields.io/pub/v/cloud_functions_tizen.svg)](https://pub.dev/packages/cloud_functions_tizen)       | [Cloud Functions](https://firebase.google.com/products/functions)|
| [`firebase_app_installations_tizen`][p_inst] | [![pub package](https://img.shields.io/pub/v/firebase_app_installations_tizen.svg)](https://pub.dev/packages/firebase_app_installations_tizen) | [Installations](https://firebase.google.com/docs/projects/manage-installations) |
| [`firebase_remote_config_tizen`][p_rc]       | [![pub package](https://img.shields.io/pub/v/firebase_remote_config_tizen.svg)](https://pub.dev/packages/firebase_remote_config_tizen)         | [Remote Config](https://firebase.google.com/products/remote-config) |
| [`firebase_ai_tizen`][p_ai]          | [![pub package](https://img.shields.io/pub/v/firebase_ai_tizen.svg)](https://pub.dev/packages/firebase_ai_tizen)               | [Firebase AI](https://firebase.google.com/docs/ai-logic)         |

## Supported devices

| API level | TV  | TV emulator |
|:---------:|:---:|:-----------:|
|    6.0    | ✔️   | ✔️           |

Raspberry Pi targets are expected to work but are not tested by CI.

## Not supported

The following FlutterFire plugins cannot be implemented meaningfully on Tizen
and are intentionally out of scope:

| Plugin                                 | Reason                                                                |
|----------------------------------------|-----------------------------------------------------------------------|
| `cloud_firestore`                      | Listener/offline parity requires a separate multi-quarter project.    |
| `firebase_messaging`                   | FCM registration is bound to Google Play Services / APNs.             |
| `firebase_analytics`                   | Uses a proprietary, undocumented wire protocol.                       |
| `firebase_crashlytics`                 | Requires NDK stack unwinding and a proprietary reporting endpoint.    |
| `firebase_performance`                 | Proprietary trace beacon endpoint.                                    |
| `firebase_in_app_messaging`            | Requires a targeting / rendering stack that is not portable.          |
| `firebase_app_check`                   | No Play Integrity / App Attest / reCAPTCHA provider on Tizen.         |
| `firebase_dynamic_links`               | Firebase service shut down on 2025-08-25.                             |

## Design notes

- All plugins are Dart-only; the Tizen implementation is registered via
  `flutter.plugin.platforms.tizen.dartPluginClass` in each package's
  `pubspec.yaml`.
- A single `firebase_dart` runtime is owned by `firebase_core_tizen`; every
  other plugin resolves Firebase apps through it, so a multi-plugin app does
  not duplicate the runtime or its state.
- Auth tokens are brokered through one shared `TizenAuthContext`. Cloud
  Functions, Storage, Remote Config, and App Installations never run their own
  token refresh loop — they subscribe to `TizenAuthContext` to avoid token
  churn and stale-credential races.
- Docs for the architecture rewrite and experimental non-pure-Dart backends
  live under [`docs/`](./docs/).

## License

See [LICENSE](./LICENSE).

[federated]: https://docs.flutter.dev/packages-and-plugins/developing-packages#non-endorsed-federated-plugin
[FlutterFire]: https://github.com/firebase/flutterfire
[firebase_dart]: https://pub.dev/packages/firebase_dart
[p_core]: ./packages/firebase_core
[p_auth]: ./packages/firebase_auth
[p_db]: ./packages/firebase_database
[p_stg]: ./packages/firebase_storage
[p_fn]: ./packages/cloud_functions
[p_inst]: ./packages/firebase_app_installations
[p_rc]: ./packages/firebase_remote_config
[p_ai]: ./packages/firebase_ai
