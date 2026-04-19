# firebase_ai_tizen

[![pub package](https://img.shields.io/pub/v/firebase_ai_tizen.svg)](https://pub.dev/packages/firebase_ai_tizen)

The Tizen implementation of [`firebase_ai`](https://pub.dev/packages/firebase_ai) —
Firebase AI Logic's Flutter client.

## Required privileges

```xml
<privileges>
  <privilege>http://tizen.org/privilege/internet</privilege>
</privileges>
```

## Usage

```yaml
dependencies:
  firebase_ai: ^3.11.0
  firebase_ai_tizen: ^0.1.0
  firebase_core: ^4.7.0
  firebase_core_tizen: ^2.0.0
```

```dart
import 'package:firebase_ai/firebase_ai.dart';

final GenerativeModel model = FirebaseAI.googleAI().generativeModel(
  model: 'gemini-2.5-flash',
);
final GenerateContentResponse response =
    await model.generateContent(<Content>[
  Content.text('Explain Tizen TV apps in one sentence.'),
]);
print(response.text);
```

## Supported devices

| Tizen version | TV | TV emulator |
|:-------------:|:--:|:-----------:|
| 6.0 and above | ✔️  | ✔️           |

## Limitations

* Only the `googleAI` backend (`generativelanguage.googleapis.com`) is
  implemented. Vertex AI gRPC-native streaming (Imagen live sessions) is
  out of scope for v0.1.0.
* Function-calling tool responses are supported, but advanced tool
  orchestration that relies on gRPC-only tool contexts is not.
