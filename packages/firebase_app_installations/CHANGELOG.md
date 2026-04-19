## 0.1.0

* Initial release: Tizen implementation of `firebase_app_installations`
  backed by a REST client (`firebaseinstallations.googleapis.com/v1/...`).
* FIDs are generated following the Firebase JS SDK algorithm: 17 random
  bytes, top 4 bits set to `0111`, base64url-encoded to 22 characters.
* Tokens are persisted in-memory and refreshed through a singleflight
  broker so concurrent callers never trigger duplicate REST round trips.
* `onIdChanged` stream is broadcast; FID changes (e.g. after `delete()`)
  are emitted immediately.
