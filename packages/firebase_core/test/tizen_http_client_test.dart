// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    TizenHttpClient.instance.closeForTesting();
  });

  group('TizenHttpClient', () {
    test('sendJson parses a 2xx JSON body', () async {
      TizenHttpClient.instance.debugOverrideClient(
        MockClient((http.Request request) async {
          expect(request.url.path, '/v1/echo');
          return http.Response(
            jsonEncode(<String, Object?>{'ok': true}),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final Map<String, Object?> response =
          await TizenHttpClient.instance.sendJson(
        method: 'POST',
        url: Uri.parse('https://example.test/v1/echo'),
        body: <String, Object?>{'k': 'v'},
      );
      expect(response['ok'], isTrue);
    });

    test('sendJson throws TizenFirebaseHttpException on a non-2xx', () async {
      TizenHttpClient.instance.debugOverrideClient(
        MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'error': <String, Object?>{
                'status': 'UNAUTHENTICATED',
                'message': 'invalid token',
              }
            }),
            401,
          );
        }),
      );

      await expectLater(
        TizenHttpClient.instance.sendJson(
          method: 'GET',
          url: Uri.parse('https://example.test/v1/fail'),
        ),
        throwsA(
          isA<TizenFirebaseHttpException>()
              .having((TizenFirebaseHttpException e) => e.statusCode,
                  'statusCode', 401)
              .having((TizenFirebaseHttpException e) => e.code, 'code',
                  'UNAUTHENTICATED')
              .having((TizenFirebaseHttpException e) => e.message, 'message',
                  'invalid token'),
        ),
      );
    });

    test('non-JSON response surfaces as internal error', () async {
      TizenHttpClient.instance.debugOverrideClient(
        MockClient((http.Request request) async {
          return http.Response('not-json', 200,
              headers: <String, String>{'content-type': 'text/plain'});
        }),
      );

      await expectLater(
        TizenHttpClient.instance.sendJson(
          method: 'GET',
          url: Uri.parse('https://example.test/raw'),
        ),
        throwsA(isA<Object>()),
      );
    });
  });
}
