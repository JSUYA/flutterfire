## 0.2.0

* **BREAKING**: Rewritten as a pure-Dart federated plugin. The native
  `tizen/` directory, its `.so` dependencies, and the
  `pluginClass`/`fileName` declarations in `pubspec.yaml` are gone.
* Delegates every Firebase Realtime Database call to the shared
  `firebase_dart` runtime owned by `firebase_core_tizen` (2.0.0+).
* Supports `onValue` / `onChildAdded` / `onChildChanged` / `onChildMoved` /
  `onChildRemoved` streams, `get`, `set`, `update`, `push`, `remove`,
  `runTransaction`, `onDisconnect`, and ordered queries.
* `setPersistenceEnabled(true)` throws `UnimplementedError` — the
  firebase_dart persistence path has an unresolved growth bug (#63) that is
  unsafe on low-storage TVs. Cache stays in memory.
* Bumped SDK constraints to Dart 3.6 / Flutter 3.27.

## 0.1.0

* Initial release.
