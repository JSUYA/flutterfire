// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_ai_tizen/firebase_ai_tizen.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    TizenHttpClient.instance.closeForTesting();
  });

  group('AiRestClient', () {
    test('generateContent forwards the body and parses the response', () async {
      TizenHttpClient.instance.debugOverrideClient(
        MockClient((http.Request request) async {
          expect(request.url.host, 'generativelanguage.googleapis.com');
          expect(
            request.url.path,
            '/v1beta/models/gemini-2.5-flash:generateContent',
          );
          expect(jsonDecode(request.body), <String, Object?>{'prompt': 'hi'});
          return http.Response(
            jsonEncode(<String, Object?>{'candidates': <Object>[]}),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final AiRestClient client =
          AiRestClient(apiKey: 'demo', appName: '[DEFAULT]');
      final Map<String, Object?> response = await client.generateContent(
        model: 'gemini-2.5-flash',
        body: <String, Object?>{'prompt': 'hi'},
      );
      expect(response.containsKey('candidates'), isTrue);
    });

    test('streamGenerateContent emits each SSE event', () async {
      TizenHttpClient.instance.debugOverrideClient(
        MockClient.streaming((http.BaseRequest request, _) async {
          expect(request.url.queryParameters['alt'], 'sse');
          final List<int> body = utf8.encode(
            'data: ${jsonEncode(<String, Object?>{"chunk": 1})}\n\n'
            'data: ${jsonEncode(<String, Object?>{"chunk": 2})}\n\n'
            'data: [DONE]\n\n',
          );
          return http.StreamedResponse(
            Stream<List<int>>.value(body),
            200,
            headers: <String, String>{'content-type': 'text/event-stream'},
          );
        }),
      );
      final AiRestClient client =
          AiRestClient(apiKey: 'demo', appName: '[DEFAULT]');
      final List<Map<String, Object?>> events =
          await client.streamGenerateContent(
        model: 'gemini-2.5-flash',
        body: <String, Object?>{'prompt': 'hi'},
      ).toList();
      expect(events, <Map<String, Object?>>[
        <String, Object?>{'chunk': 1},
        <String, Object?>{'chunk': 2},
      ]);
    });
  });
}
