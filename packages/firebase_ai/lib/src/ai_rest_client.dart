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
  /// event as a parsed Map.
  ///
  /// Implements the SSE wire format correctly — an event consists of one or
  /// more `data:` lines separated by a blank line. Multi-line `data:` values
  /// are joined with a newline (per `text/event-stream` spec) before being
  /// JSON-decoded.
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
    final StringBuffer buffer = StringBuffer();
    Future<void> flush(StreamController<Map<String, Object?>> _) async {}
    await for (final String line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.isEmpty) {
        // End of event: emit buffered data, if any.
        final String payload = buffer.toString();
        buffer.clear();
        if (payload.isEmpty) {
          continue;
        }
        final Object? decoded = jsonDecode(payload);
        if (decoded is Map<String, Object?>) {
          yield decoded;
        }
        continue;
      }
      if (line.startsWith(':')) {
        // SSE comment; ignore.
        continue;
      }
      if (!line.startsWith('data:')) {
        // Other SSE fields (event:, id:, retry:) are not meaningful for
        // Gemini streaming responses.
        continue;
      }
      // Per spec, a single leading space after the colon is ignored; keep
      // the rest verbatim so multi-line JSON is reconstructed correctly.
      String payloadFragment = line.substring('data:'.length);
      if (payloadFragment.startsWith(' ')) {
        payloadFragment = payloadFragment.substring(1);
      }
      if (buffer.isNotEmpty) {
        buffer.write('\n');
      }
      buffer.write(payloadFragment);
    }
    // Handle streams that terminate without a trailing blank line.
    final String tail = buffer.toString();
    if (tail.isNotEmpty) {
      final Object? decoded = jsonDecode(tail);
      if (decoded is Map<String, Object?>) {
        yield decoded;
      }
    }
    // flush is unused but preserves the closure-capture style for future
    // instrumentation hooks without altering the public API.
    await flush(StreamController<Map<String, Object?>>());
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
