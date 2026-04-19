## 0.2.0

* **BREAKING**: Rewritten as a pure-Dart federated plugin that talks to
  Cloud Functions over standard HTTPS. The native `tizen/` directory, its
  `.so` dependencies, and the `pluginClass`/`fileName` declarations are gone.
* `httpsCallable(name)` hits the gen1 endpoint
  `https://<region>-<project>.cloudfunctions.net/<name>`.
* `httpsCallableWithUri(uri)` supports gen2 functions hosted on Cloud Run
  (`https://<name>-<hash>-<region>.a.run.app`) by taking the URL directly.
* Every callable request carries a fresh `Authorization: Bearer <idToken>`
  sourced from `TizenAuthContext` — the token cache is shared with Storage
  and Remote Config so there is no per-package refresh loop.
* Errors are mapped onto `FirebaseFunctionsException` with the canonical
  gRPC code (`cancelled`, `invalid-argument`, `unauthenticated`, …) and
  preserve the server-supplied `details` list.

Intentionally unsupported (throws `UnimplementedError`): streaming
callables, emulator origin override, App Check token injection (no App
Check provider available on Tizen).

## 0.1.0

* Initial release.
