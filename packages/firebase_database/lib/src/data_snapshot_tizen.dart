// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

import 'database_reference_tizen.dart';
import 'firebase_database_tizen_impl.dart';

/// Tizen [DataSnapshotPlatform] implementation that wraps a
/// `firebase_dart.DataSnapshot`.
///
/// `firebase_dart 1.6.2` exposes only `key` and `value` on its
/// `DataSnapshot`; there is no `priority`, `exists`, `children`, `child`,
/// or `ref`. We therefore derive the missing pieces from the carried
/// value map and from the Tizen-side reference that created the snapshot.
class DataSnapshotTizen extends DataSnapshotPlatform {
  /// Wraps [snapshot] belonging to [reference].
  DataSnapshotTizen(
    this._database,
    this._snapshot, {
    required DatabaseReferencePlatform reference,
  }) : super(reference, _snapshotToMap(_snapshot));

  /// Constructs a standalone snapshot from a pre-resolved (key, value) pair
  /// — used when deriving child snapshots from the parent's value map,
  /// because `fd.DataSnapshot` does not expose `child()`.
  DataSnapshotTizen.fromValue({
    required FirebaseDatabaseTizen database,
    required DatabaseReferencePlatform reference,
    required String? key,
    required Object? value,
  })  : _database = database,
        _snapshot = _LocalDataSnapshot(key, value),
        super(reference, <String, Object?>{
          'key': key,
          'value': value,
          'priority': null,
        });

  final FirebaseDatabaseTizen _database;
  final fd.DataSnapshot _snapshot;

  static Map<String, Object?> _snapshotToMap(fd.DataSnapshot snapshot) {
    return <String, Object?>{
      'key': snapshot.key,
      'value': snapshot.value,
      // firebase_dart does not expose priority on DataSnapshot.
      'priority': null,
    };
  }

  @override
  bool get exists => _snapshot.value != null;

  @override
  Object? get value => _snapshot.value;

  @override
  Object? get priority => null;

  @override
  Iterable<DataSnapshotPlatform> get children sync* {
    final Object? value = _snapshot.value;
    if (value is! Map) {
      return;
    }
    final DatabaseReferenceTizen parentRef = ref as DatabaseReferenceTizen;
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final String childKey = entry.key?.toString() ?? '';
      yield DataSnapshotTizen.fromValue(
        database: _database,
        reference: DatabaseReferenceTizen(
          _database,
          parentRef.dartReference.child(childKey),
        ),
        key: childKey,
        value: entry.value,
      );
    }
  }

  @override
  DataSnapshotPlatform child(String childPath) {
    final DatabaseReferenceTizen parentRef = ref as DatabaseReferenceTizen;
    final fd.DatabaseReference childDartRef =
        parentRef.dartReference.child(childPath);
    return DataSnapshotTizen.fromValue(
      database: _database,
      reference: DatabaseReferenceTizen(_database, childDartRef),
      key: childPath.split('/').last,
      value: _resolveChildValue(childPath),
    );
  }

  Object? _resolveChildValue(String path) {
    Object? cursor = _snapshot.value;
    for (final String segment in path.split('/')) {
      if (segment.isEmpty) {
        continue;
      }
      if (cursor is! Map) {
        return null;
      }
      cursor = cursor[segment];
    }
    return cursor;
  }
}

/// Lightweight in-memory [fd.DataSnapshot] stand-in used by `child()` and
/// `children` so we can carry a derived (key, value) pair without
/// synthesising a real `DataSnapshot` subclass.
class _LocalDataSnapshot implements fd.DataSnapshot {
  _LocalDataSnapshot(this.key, this.value);

  @override
  final String? key;

  @override
  final dynamic value;
}
