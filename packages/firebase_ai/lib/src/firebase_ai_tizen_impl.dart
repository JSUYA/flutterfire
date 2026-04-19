// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';

import 'ai_rest_client.dart';

/// Tizen entry point for `firebase_ai`.
///
/// `firebase_ai` does not yet expose a federated platform interface, so the
/// Tizen package deliberately avoids pretending to be an implementation of
/// the upstream plugin. Instead it exposes a thin [FirebaseAiBackend]
/// wrapper that Tizen apps call directly until upstream federation lands.
///
/// ```dart
/// final FirebaseAiBackend backend = FirebaseAiTizen.backend();
/// final Map<String, Object?> response = await backend.generateContent(
///   model: 'gemini-2.5-flash',
///   body: <String, Object?>{...},
/// );
/// ```
///
/// [register] is intentionally a no-op: the flutter-tizen plugin tool may
/// invoke it during `GeneratedPluginRegistrant.register()`, but no Firebase
/// app exists yet at that point, so there is nothing to initialise. The
/// backend is built lazily on the first call to [backend].
class FirebaseAiTizen {
  FirebaseAiTizen._();

  /// Installed via `dartPluginClass: FirebaseAiTizen`.
  ///
  /// Must remain cheap and side-effect free — it runs before
  /// `Firebase.initializeApp` completes, so the real backend construction
  /// happens lazily in [backend].
  static void register() {
    // Intentionally empty: no eager Firebase.app() lookup.
  }

  static FirebaseAiBackend? _backend;

  /// Returns a Gemini/AI backend for the supplied [app] (or the default
  /// Firebase app), constructing it lazily on first use. Safe to call once
  /// `Firebase.initializeApp` has completed.
  static FirebaseAiBackend backend({FirebaseApp? app}) {
    final FirebaseAiBackend? cached = _backend;
    if (cached != null && app == null) {
      return cached;
    }
    final FirebaseApp resolved = app ?? Firebase.app();
    final FirebaseAiBackend built = FirebaseAiBackend._fromApp(resolved);
    if (app == null) {
      _backend = built;
    }
    return built;
  }

  /// Test hook: swap the backing client.
  @visibleForTesting
  static void debugSetBackend(FirebaseAiBackend? backend) {
    _backend = backend;
  }
}

/// Backend wrapper exposed to apps and to the upstream `firebase_ai` plugin.
class FirebaseAiBackend {
  /// Creates a backend using an explicit [client].
  FirebaseAiBackend({required AiRestClient client}) : _client = client;

  /// Factory that builds a client from [app]'s options.
  factory FirebaseAiBackend._fromApp(FirebaseApp app) {
    return FirebaseAiBackend(
      client: AiRestClient(
        apiKey: app.options.apiKey,
        appName: app.name,
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
