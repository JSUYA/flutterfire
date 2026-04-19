// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';

import 'ai_rest_client.dart';

/// Tizen entry point for `firebase_ai`.
///
/// `firebase_ai` does not (yet) expose a MethodChannel-backed
/// platform_interface in the same shape as the other plugins. The Tizen
/// implementation therefore registers a `FirebaseAiBackend` accessor that
/// Tizen consumers can call through a wrapper API:
///
/// ```dart
/// final FirebaseAiBackend backend = FirebaseAiTizen.backend();
/// final Map<String, Object?> response = await backend.generateContent(
///   model: 'gemini-2.5-flash',
///   body: <String, Object?>{...},
/// );
/// ```
///
/// Once `firebase_ai` ships a formal federated interface we switch to that
/// without touching app code.
class FirebaseAiTizen {
  FirebaseAiTizen._();

  /// Installed via `dartPluginClass: FirebaseAiTizen`.
  static void register() {
    _backend = FirebaseAiBackend._fromAppName();
  }

  static FirebaseAiBackend? _backend;

  /// Returns the registered backend, or constructs one lazily on first use.
  static FirebaseAiBackend backend({FirebaseApp? app}) {
    return _backend ??= FirebaseAiBackend._fromAppName(app: app);
  }

  /// Test hook: swap the backing client.
  @visibleForTesting
  static void debugSetBackend(FirebaseAiBackend backend) {
    _backend = backend;
  }
}

/// Backend wrapper exposed to apps and to the upstream `firebase_ai` plugin.
class FirebaseAiBackend {
  /// Creates a backend using an explicit [client].
  FirebaseAiBackend({required AiRestClient client}) : _client = client;

  /// Factory that builds a client from the default Firebase app's options.
  factory FirebaseAiBackend._fromAppName({FirebaseApp? app}) {
    final FirebaseApp resolved = app ?? Firebase.app();
    return FirebaseAiBackend(
      client: AiRestClient(
        apiKey: resolved.options.apiKey,
        appName: resolved.name,
      ),
    );
  }

  final AiRestClient _client;

  /// Performs a non-streaming `generateContent` call.
  Future<Map<String, Object?>> generateContent({
    required String model,
    required Map<String, Object?> body,
  }) {
    return _client.generateContent(model: model, body: body);
  }

  /// Performs a streaming `generateContent` call.
  Stream<Map<String, Object?>> streamGenerateContent({
    required String model,
    required Map<String, Object?> body,
  }) {
    return _client.streamGenerateContent(model: model, body: body);
  }

  /// Performs a `countTokens` call.
  Future<Map<String, Object?>> countTokens({
    required String model,
    required Map<String, Object?> body,
  }) {
    return _client.countTokens(model: model, body: body);
  }
}
