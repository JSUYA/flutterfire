## 2.0.0

* **BREAKING**: Rewritten as a pure-Dart federated plugin. The previous
  implementation bundled cross-compiled Firebase C++ SDK binaries; those are
  gone, along with the `tizen/` native directory and the `pluginClass` /
  `fileName` entries in `pubspec.yaml`.
* Firebase app registry is now backed by [`firebase_dart`][fd], initialized
  once per process inside an isolate via `FirebaseDart.setup(isolated: true)`.
* Introduces the shared runtime singletons that sibling Firebase Tizen plugins
  depend on: `FirebaseTizenRuntime`, `TizenAuthContext`, and
  `TizenHttpClient`. These are annotated `@internal` — application code must
  continue to use the upstream `firebase_core` API.
* Minimum SDK bumped to Dart 3.6 and Flutter 3.27 in line with
  `flutter-tizen/plugins`.

Migration notes for apps upgrading from `1.x`:

* Delete any `pluginClass: FirebaseCoreTizenPlugin` / `fileName:` entries if
  you forked the old `pubspec.yaml`.
* `SetAutomaticDataCollectionEnabled` and
  `SetAutomaticResourceManagementEnabled` now throw
  `UnimplementedError` instead of silently no-oping. Gate those calls on
  `defaultTargetPlatform`.

[fd]: https://pub.dev/packages/firebase_dart

## 1.0.1

* Update firebase_core to 2.17.0.

## 1.0.0

* Initial release.
