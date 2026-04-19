// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_remote_config_tizen/firebase_remote_config_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseRemoteConfigTizen — unsupported surface', () {
    test('onConfigUpdated stream emits UnimplementedError', () async {
      FirebaseRemoteConfigTizen.register();
      final FirebaseRemoteConfigTizen instance =
          FirebaseRemoteConfigTizen();
      await expectLater(
        instance.onConfigUpdated.first,
        throwsA(isA<UnimplementedError>().having(
          (UnimplementedError e) => e.message,
          'message',
          contains('onConfigUpdated'),
        )),
      );
    });
  });

  group('RemoteConfigFetchResponse', () {
    test('notModified preserves empty payload', () {
      const RemoteConfigFetchResponse response =
          RemoteConfigFetchResponse.notModified();
      expect(response.notModified, isTrue);
      expect(response.entries, isEmpty);
      expect(response.etag, isNull);
    });

    test('updated exposes entries and etag', () {
      const RemoteConfigFetchResponse response =
          RemoteConfigFetchResponse.updated(
        entries: <String, Object?>{'greeting': 'hi'},
        etag: 'abc',
      );
      expect(response.notModified, isFalse);
      expect(response.entries, <String, Object?>{'greeting': 'hi'});
      expect(response.etag, 'abc');
    });
  });
}
