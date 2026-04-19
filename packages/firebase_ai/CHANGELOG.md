## 0.1.0

* Initial release.
* Tizen implementation of `firebase_ai` as a thin HTTPS client to the
  `generativelanguage.googleapis.com/v1beta` endpoint that backs Firebase
  AI Logic.
* Supports `generateContent`, streaming variant via Server-Sent Events
  (`?alt=sse`), and `countTokens`. Requests carry the Firebase API key and,
  when a user is signed in, the ID token from `TizenAuthContext`.
