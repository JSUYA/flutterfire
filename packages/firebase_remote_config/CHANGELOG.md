## 0.1.0

* Initial release: Tizen implementation of `firebase_remote_config` backed
  by the Remote Config fetch endpoint the native SDKs use
  (`firebaseremoteconfig.googleapis.com/v1/projects/<id>/namespaces/firebase:fetch`).
* Installation auth tokens come from
  `firebase_app_installations_tizen`; the Remote Config client never runs
  its own Installations flow.
* `fetch`, `activate`, `fetchAndActivate`, `setConfigSettings`,
  `setDefaults`, `getAll`, `getBool`, `getInt`, `getDouble`, `getString`,
  `getValue`, `lastFetchTime`, and `lastFetchStatus` are implemented.
* Responses are cached with an ETag so follow-up fetches emit a conditional
  `If-None-Match`; a 304 response keeps the previous payload intact.
* `onConfigUpdated` streaming throws `UnimplementedError` — the realtime
  Config protocol is expensive to hold open on a TV.
