// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

import 'database_reference_tizen.dart';
import 'firebase_database_tizen_impl.dart';

/// Tizen [DataSnapshotPlatform] implementation that wraps a
/// `firebase_dart.DataSnapshot`.
class DataSnapshotTizen extends DataSnapshotPlatform {
  /// Wraps [snapshot] belonging to [reference].
  DataSnapshotTizen(
    this._database,
    this._snapshot, {
    required DatabaseReferencePlatform reference,
  }) : super(reference, _snapshotToMap(_snapshot));

  final FirebaseDatabaseTizen _database;
  final fd.DataSnapshot _snapshot;

  static Map<String, Object?> _snapshotToMap(fd.DataSnapshot snapshot) {
    return <String, Object?>{
      'key': snapshot.key,
      'value': snapshot.value,
      'priority': snapshot.priority,
    };
  }

  @override
  bool get exists => _snapshot.exists;

  @override
  Object? get value => _snapshot.value;

  @override
  Object? get priority => _snapshot.priority;

  @override
  Iterable<DataSnapshotPlatform> get children sync* {
    for (final fd.DataSnapshot child in _snapshot.children) {
      final DatabaseReferenceTizen childRef = DatabaseReferenceTizen(
        _database,
        _database.dartDatabase.reference().child(child.ref.path.toString()),
      );
      yield DataSnapshotTizen(_database, child, reference: childRef);
    }
  }

  @override
  bool hasChild(String path) {
    return _snapshot.hasChild(path);
  }

  @override
  DataSnapshotPlatform child(String childPath) {
    final fd.DataSnapshot child = _snapshot.child(childPath);
    final DatabaseReferenceTizen childRef = DatabaseReferenceTizen(
      _database,
      _database.dartDatabase.reference().child(child.ref.path.toString()),
    );
    return DataSnapshotTizen(_database, child, reference: childRef);
  }
}
