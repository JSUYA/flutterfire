// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';

import 'data_snapshot_tizen.dart';

/// Tizen [DatabaseEventPlatform] delegate.
class DatabaseEventTizen extends DatabaseEventPlatform {
  /// Creates an event of [type] carrying [snapshot].
  DatabaseEventTizen({
    required DataSnapshotTizen snapshot,
    required this.previousChildKey,
    required this.type,
  }) : super(<String, Object?>{
          'snapshot': <String, Object?>{
            'key': snapshot.key,
            'value': snapshot.value,
            'priority': snapshot.priority,
          },
          'previousChildKey': previousChildKey,
          'eventType': type.name,
        }) {
    _snapshot = snapshot;
  }

  late final DataSnapshotTizen _snapshot;

  /// Preceding child key for `onChild*` events.
  @override
  final String? previousChildKey;

  /// Event category.
  @override
  final DatabaseEventType type;

  @override
  DataSnapshotPlatform get snapshot => _snapshot;
}
