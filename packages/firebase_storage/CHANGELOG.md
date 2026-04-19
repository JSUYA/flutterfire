## 0.2.0

* **BREAKING**: Rewritten as a pure-Dart federated plugin backed by a direct
  Firebase Storage REST client. The previous native `tizen/` directory, the
  `pluginClass`/`fileName` declarations, and the per-plugin `firebase_app.so`
  binaries are gone.
* Uploads:
  * `putData` ≤ 8 MiB → multipart upload; `> 8 MiB` → resumable upload in
    256 KiB chunks so we never buffer the whole payload in RAM.
  * `putFile` streams the file from disk (`openRead`) instead of reading it
    into memory synchronously.
  * `putString` supports `raw`, `base64`, `base64url`, and `dataUrl` formats.
* Downloads:
  * `getData(maxSize)` enforces the limit by aborting the stream mid-read
    when the body exceeds `maxSize`.
  * `writeToFile` streams directly to disk with `addStream(response.stream)`.
* Metadata: `getMetadata`, `updateMetadata`, `delete`.
* Listing: `list` + `listAll` with `pageToken` propagation.
* Error mapping: HTTP status → canonical Firebase Storage code
  (`object-not-found`, `unauthorized`, `canceled`, `quota-exceeded`, …).
* ID tokens come from the shared `TizenAuthContext` singleflight cache in
  `firebase_core_tizen`, so Storage never runs its own refresh timer.

Intentionally unsupported (throws `UnimplementedError`): `useStorageEmulator`,
`TaskPlatform.pause` / `TaskPlatform.resume`, `putBlob` (web-only), and
download-token issuance (use console-minted tokens).

## 0.1.0

* Initial release.
