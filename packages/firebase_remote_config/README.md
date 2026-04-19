# firebase_remote_config_tizen

[![pub package](https://img.shields.io/pub/v/firebase_remote_config_tizen.svg)](https://pub.dev/packages/firebase_remote_config_tizen)

The Tizen implementation of
[`firebase_remote_config`](https://pub.dev/packages/firebase_remote_config).

Non-endorsed federated plugin. Depends on
`firebase_app_installations_tizen` for the installation auth token required
by the fetch endpoint.

## Required privileges

```xml
<privileges>
  <privilege>http://tizen.org/privilege/internet</privilege>
</privileges>
```

## Usage

```yaml
dependencies:
  firebase_app_installations_tizen: ^0.1.0
  firebase_core: ^4.7.0
  firebase_core_tizen: ^2.0.0
  firebase_remote_config: ^6.4.0
  firebase_remote_config_tizen: ^0.1.0
```

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

await FirebaseRemoteConfig.instance
    .setDefaults(<String, Object?>{'greeting': 'Hi Tizen'});
await FirebaseRemoteConfig.instance.fetchAndActivate();
print(FirebaseRemoteConfig.instance.getString('greeting'));
```

## Supported devices

| Tizen version | TV | TV emulator |
|:-------------:|:--:|:-----------:|
| 6.0 and above | ✔️  | ✔️           |

## Limitations

* `onConfigUpdated` (realtime Remote Config) throws `UnimplementedError`.
  The streaming endpoint keeps a long-lived connection open; Tizen TVs drop
  sockets aggressively in standby, and we'd rather surface a clear error
  than silently stop delivering updates.
* The fetch endpoint (`firebaseremoteconfig.googleapis.com/v1/projects/{id}/
  namespaces/firebase:fetch`) is not covered by Firebase's public API
  contract. Behaviour may change without notice; `ETag` + `304 Not Modified`
  fallback keeps the last-known config in place if the server response
  shape drifts.
