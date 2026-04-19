// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String _app = '[DEFAULT]';

  setUp(() async {
    await TizenAuthContext.instance.resetForTesting();
  });

  tearDown(() async {
    await TizenAuthContext.instance.resetForTesting();
  });

  group('TizenAuthContext', () {
    test('returns null when no provider is registered', () async {
      final String? token = await TizenAuthContext.instance.getIdToken(_app);
      expect(token, isNull);
    });

    test('singleflights concurrent refreshes to a single provider call',
        () async {
      int invocations = 0;
      final Completer<String> gate = Completer<String>();
      TizenAuthContext.instance.registerProvider(_app, ({
        required bool forceRefresh,
      }) async {
        invocations++;
        return gate.future;
      });

      final Future<String?> a = TizenAuthContext.instance.getIdToken(_app);
      final Future<String?> b = TizenAuthContext.instance.getIdToken(_app);
      final Future<String?> c =
          TizenAuthContext.instance.getIdToken(_app, forceRefresh: true);

      gate.complete('tok');

      final List<String?> results = await Future.wait<String?>(<Future<String?>>[
        a,
        b,
        c,
      ]);
      expect(results, <String?>['tok', 'tok', 'tok']);
      // Only the first call (or the first forceRefresh) should hit the
      // provider; follow-ups read the cached token.
      expect(invocations, lessThanOrEqualTo(2));
    });

    test('notifyToken updates the cache and broadcasts', () async {
      final List<String?> events = <String?>[];
      final StreamSubscription<String?> sub =
          TizenAuthContext.instance.idTokenChanges(_app).listen(events.add);

      TizenAuthContext.instance.notifyToken(_app, 'first');
      TizenAuthContext.instance.notifyToken(_app, 'second');
      TizenAuthContext.instance.clear(_app);

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, <String?>['first', 'second', null]);
      expect(await TizenAuthContext.instance.getIdToken(_app), isNull);
    });

    test('forceRefresh bypasses the cache', () async {
      int call = 0;
      TizenAuthContext.instance.registerProvider(_app, ({
        required bool forceRefresh,
      }) async {
        call++;
        return 't$call';
      });

      expect(await TizenAuthContext.instance.getIdToken(_app), 't1');
      expect(await TizenAuthContext.instance.getIdToken(_app), 't1');
      expect(
        await TizenAuthContext.instance
            .getIdToken(_app, forceRefresh: true),
        't2',
      );
    });
  });
}
