# firebase_app_installations_tizen

[![pub package](https://img.shields.io/pub/v/firebase_app_installations_tizen.svg)](https://pub.dev/packages/firebase_app_installations_tizen)

The Tizen implementation of
[`firebase_app_installations`](https://pub.dev/packages/firebase_app_installations).

Non-endorsed federated plugin. Firebase Installations issues a Firebase
Installation ID (FID) and short-lived installation auth token. Tizen sibling
plugins that need an installation token — in particular
`firebase_remote_config_tizen` — depend on this package for the Installations
REST flow.

## Required privileges

```xml
<privileges>
  <privilege>http://tizen.org/privilege/internet</privilege>
</privileges>
```

## Usage

```yaml
dependencies:
  firebase_app_installations: ^0.4.2
  firebase_app_installations_tizen: ^0.1.0
  firebase_core: ^4.7.0
  firebase_core_tizen: ^2.0.0
```

```dart
import 'package:firebase_app_installations/firebase_app_installations.dart';

final String fid = await FirebaseInstallations.instance.getId();
final String token =
    await FirebaseInstallations.instance.getToken(true);
```

## Supported devices

| Tizen version | TV | TV emulator |
|:-------------:|:--:|:-----------:|
| 6.0 and above | ✔️  | ✔️           |

## Limitations

* FIDs are cached in memory only. Persisting them to Tizen app-data storage
  would require an encrypted cache; add that in a later release.
* Analytics/Crashlytics/Performance are unavailable on Tizen, so the FID is
  not forwarded to any Firebase telemetry service.
