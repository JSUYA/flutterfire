# FlutterFire for Tizen

FlutterFire for Tizen is being redesigned as a pure Dart federated plugin set that fits the `flutter-tizen/plugins` package layout.

The previous approach bundled cross-compiled Firebase C++ shared libraries into each plugin. That created three structural problems on Tizen:

- package size grew quickly as more Firebase plugins were added
- each plugin duplicated native libraries and build artifacts
- the desktop-style C++ integration path is not a good long-term fit for `flutter-tizen/plugins`

The current implementation removes the `.so` packaging model and replaces it with:

- `firebase_dart` for Core, Auth, Realtime Database, and Storage
- direct HTTPS callable protocol support for Cloud Functions
- pure Dart Tizen plugin registration via `dartPluginClass`

## Implemented Packages

| Package | Status | Backend |
| --- | --- | --- |
| `firebase_core_tizen` | Implemented | `firebase_dart` |
| `firebase_auth_tizen` | Implemented | `firebase_dart` |
| `firebase_database_tizen` | Implemented | `firebase_dart` |
| `firebase_storage_tizen` | Implemented | `firebase_dart` |
| `cloud_functions_tizen` | Implemented | HTTPS callable protocol |

## Design Direction

- Keep each package in the same shape expected by `flutter-tizen/plugins`.
- Prefer pure Dart adapters over bundled native Firebase SDK binaries.
- Stay aligned with current FlutterFire major interfaces:
  - `firebase_core` 4.x
  - `firebase_auth` 6.x
  - `cloud_functions` 6.x
  - `firebase_database` 12.x
  - `firebase_storage` 13.x

Additional design notes and the migration plan live in [docs/flutter_tizen_plugins_migration.md](docs/flutter_tizen_plugins_migration.md).

## Experimental Non-Pure-Dart Backends

For comparison work, the repository also includes three experimental non-pure-Dart backend implementations under [experimental/](experimental/):

- shared C++ runtime host
- one-shot native protocol CLI
- WebView JavaScript bridge

The design notes for those experiments live in [docs/experimental_non_pure_dart_backends.md](docs/experimental_non_pure_dart_backends.md).

## Current Limitations

- `firebase_auth_tizen`
  - phone auth is not implemented
  - popup and redirect OAuth flows are not implemented
  - auth emulator support is not implemented
- `cloud_functions_tizen`
  - callable streaming is not implemented
- `firebase_storage_tizen`
  - storage emulator support is not implemented
  - download tasks are implemented as one-shot writes
- `firebase_database_tizen`
  - `startAfter` and `endBefore` are approximated through existing query cursors

## Future Candidates

- Reasonable next candidates:
  - Remote Config via REST-backed adapter
  - Firestore through a separate pure Dart or REST-based design, if API parity scope is defined narrowly
- Poor fits for now:
  - Messaging
  - Analytics
  - Crashlytics
  - Performance
  - App Check

## License

The licence is described separately in each package. [LICENSE](./LICENSE) contains the repository-wide license information.
