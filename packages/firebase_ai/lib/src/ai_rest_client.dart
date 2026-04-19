// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// HTTPS client for the Gemini / Firebase AI Logic API.
@internal
class AiRestClient {
  /// Creates a client with the project's [apiKey] and optional [host].
  AiRestClient({
    required this.apiKey,
    required this.appName,
    this.host = 'generativelanguage.googleapis.com',
    this.version = 'v1beta',
  });

  /// Firebase Web API key.
  final String apiKey;

  /// Firebase app used for ID token lookup.
  final String appName;

  /// API host.
  final String host;

  /// API version segment.
  final String version;

  Uri _modelUri(String model, String operation, {bool streaming = false}) {
    return Uri.https(
      host,
      '/$version/models/$model:$operation',
      <String, String>{
        'key': apiKey,
        if (streaming) 'alt': 'sse',
      },
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final String? idToken = await TizenAuthContext.instance.getIdToken(appName);
    return <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  /// Executes a non-streaming `generateContent` call.
  Future<Map<String, Object?>> generateContent({
    required String model,
    required Map<String, Object?> body,
  }) async {
    return TizenHttpClient.instance.sendJson(
      method: 'POST',
      url: _modelUri(model, 'generateContent'),
      headers: await _authHeaders(),
      body: body,
    );
  }

  /// Executes a streaming `generateContent` call, emitting each server
  /// chunk as a parsed Map.
  Stream<Map<String, Object?>> streamGenerateContent({
    required String model,
    required Map<String, Object?> body,
  }) async* {
    final http.StreamedResponse response =
        await TizenHttpClient.instance.sendStreamed(
      method: 'POST',
      url: _modelUri(model, 'streamGenerateContent', streaming: true),
      headers: await _authHeaders(),
      body: Stream<List<int>>.fromIterable(<List<int>>[
        utf8.encode(jsonEncode(body)),
      ]),
    );
    if (response.statusCode >= 300) {
      final String errorBody = await response.stream.bytesToString();
      throw TizenFirebaseHttpException(
        code: 'unknown',
        statusCode: response.statusCode,
        message: 'streamGenerateContent failed (${response.statusCode})',
        responseBody: errorBody,
      );
    }
    await for (final String line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.isEmpty || !line.startsWith('data:')) {
        continue;
      }
      final String payload = line.substring('data:'.length).trim();
      if (payload.isEmpty || payload == '[DONE]') {
        continue;
      }
      final Object? decoded = jsonDecode(payload);
      if (decoded is Map<String, Object?>) {
        yield decoded;
      }
    }
  }

  /// Executes a `countTokens` call.
  Future<Map<String, Object?>> countTokens({
    required String model,
    required Map<String, Object?> body,
  }) async {
    return TizenHttpClient.instance.sendJson(
      method: 'POST',
      url: _modelUri(model, 'countTokens'),
      headers: await _authHeaders(),
      body: body,
    );
  }
}
