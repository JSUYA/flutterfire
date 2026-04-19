// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

import 'data_snapshot_tizen.dart';
import 'database_event_tizen.dart';
import 'firebase_database_tizen_impl.dart';
import 'on_disconnect_tizen.dart';

/// Tizen query delegate shared by [DatabaseReferenceTizen] and composite
/// filter builders.
class QueryTizen extends QueryPlatform {
  /// Wraps [query] belonging to [database].
  QueryTizen(this._database, this._query);

  final FirebaseDatabaseTizen _database;
  final fd.Query _query;

  @override
  DatabasePlatform get database => _database;

  @override
  String get path => _query.path.toString();

  fd.Query _applyModifiers(QueryModifiers modifiers) {
    return modifiers.apply<fd.Query>(
      _query,
      orderByChild: (fd.Query q, String path) => q.orderByChild(path),
      orderByKey: (fd.Query q) => q.orderByKey(),
      orderByValue: (fd.Query q) => q.orderByValue(),
      orderByPriority: (fd.Query q) => q.orderByPriority(),
      startAt: (fd.Query q, Object? value, String? key) =>
          q.startAt(value, key),
      endAt: (fd.Query q, Object? value, String? key) => q.endAt(value, key),
      equalTo: (fd.Query q, Object? value, String? key) =>
          q.equalTo(value, key),
      limitToFirst: (fd.Query q, int limit) => q.limitToFirst(limit),
      limitToLast: (fd.Query q, int limit) => q.limitToLast(limit),
    );
  }

  @override
  DatabaseReferencePlatform get ref => DatabaseReferenceTizen(
        _database,
        _query.reference(),
      );

  Stream<DatabaseEventPlatform> _observe(
    QueryModifiers modifiers,
    DatabaseEventType type,
  ) {
    final fd.Query applied = _applyModifiers(modifiers);
    Stream<fd.Event> source;
    switch (type) {
      case DatabaseEventType.value:
        source = applied.onValue;
      case DatabaseEventType.childAdded:
        source = applied.onChildAdded;
      case DatabaseEventType.childChanged:
        source = applied.onChildChanged;
      case DatabaseEventType.childMoved:
        source = applied.onChildMoved;
      case DatabaseEventType.childRemoved:
        source = applied.onChildRemoved;
    }
    late StreamController<DatabaseEventPlatform> controller;
    StreamSubscription<fd.Event>? subscription;
    controller = StreamController<DatabaseEventPlatform>.broadcast(
      onListen: () {
        subscription = source.listen(
          (fd.Event event) {
            final DataSnapshotTizen snapshot = DataSnapshotTizen(
              _database,
              event.snapshot,
              reference: DatabaseReferenceTizen(
                _database,
                event.snapshot.ref,
              ),
            );
            controller.add(DatabaseEventTizen(
              snapshot: snapshot,
              previousChildKey: event.previousSiblingKey,
              type: type,
            ));
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Stream<DatabaseEventPlatform> observe(
    QueryModifiers modifiers,
    DatabaseEventType eventType,
  ) => _observe(modifiers, eventType);

  @override
  Stream<DatabaseEventPlatform> onValue(QueryModifiers modifiers) =>
      _observe(modifiers, DatabaseEventType.value);

  @override
  Stream<DatabaseEventPlatform> onChildAdded(QueryModifiers modifiers) =>
      _observe(modifiers, DatabaseEventType.childAdded);

  @override
  Stream<DatabaseEventPlatform> onChildChanged(QueryModifiers modifiers) =>
      _observe(modifiers, DatabaseEventType.childChanged);

  @override
  Stream<DatabaseEventPlatform> onChildMoved(QueryModifiers modifiers) =>
      _observe(modifiers, DatabaseEventType.childMoved);

  @override
  Stream<DatabaseEventPlatform> onChildRemoved(QueryModifiers modifiers) =>
      _observe(modifiers, DatabaseEventType.childRemoved);

  @override
  Future<DataSnapshotPlatform> get(QueryModifiers modifiers) async {
    final fd.DataSnapshot snapshot = await _applyModifiers(modifiers).get();
    return DataSnapshotTizen(
      _database,
      snapshot,
      reference: DatabaseReferenceTizen(_database, snapshot.ref),
    );
  }

  @override
  Future<void> keepSynced(QueryModifiers modifiers, bool value) async {
    // firebase_dart keeps queries live for the lifetime of a listener; a
    // dedicated keepSynced channel is not exposed. The call is treated as a
    // best-effort no-op, matching the on-device behaviour.
  }
}

/// Tizen [DatabaseReferencePlatform] delegate.
class DatabaseReferenceTizen extends QueryTizen
    implements DatabaseReferencePlatform {
  /// Wraps a firebase_dart [reference] belonging to [database].
  DatabaseReferenceTizen(FirebaseDatabaseTizen database, this._reference)
      : super(database, _reference);

  final fd.DatabaseReference _reference;

  /// Underlying `firebase_dart` reference, used by child snapshots.
  fd.DatabaseReference get dartReference => _reference;

  @override
  String? get key => _reference.key;

  @override
  DatabaseReferencePlatform child(String path) {
    return DatabaseReferenceTizen(_database, _reference.child(path));
  }

  @override
  DatabaseReferencePlatform? get parent {
    // fd.DatabaseReference.parent is a METHOD, not a getter.
    final fd.DatabaseReference? parent = _reference.parent();
    if (parent == null) {
      return null;
    }
    return DatabaseReferenceTizen(_database, parent);
  }

  @override
  DatabaseReferencePlatform root() =>
      // fd.DatabaseReference.root and upstream root() are both methods.
      DatabaseReferenceTizen(_database, _reference.root());

  @override
  OnDisconnectPlatform onDisconnect() {
    return OnDisconnectTizen(this, _reference);
  }

  @override
  DatabaseReferencePlatform push() {
    return DatabaseReferenceTizen(_database, _reference.push());
  }

  @override
  Future<void> set(Object? value) => _reference.set(value);

  @override
  Future<void> setWithPriority(Object? value, Object? priority) =>
      // fd.DatabaseReference has no setWithPriority; set() takes an
      // optional priority.
      _reference.set(value, priority: priority);

  @override
  Future<void> setPriority(Object? priority) =>
      _reference.setPriority(priority);

  @override
  Future<void> update(Map<String, Object?> value) => _reference.update(value);

  @override
  Future<void> remove() => _reference.remove();

  @override
  Future<TransactionResultPlatform> runTransaction(
    TransactionHandler transactionHandler, {
    bool applyLocally = true,
  }) async {
    if (!applyLocally) {
      throw UnimplementedError(
        'runTransaction(applyLocally: false) is not supported by '
        'firebase_database_tizen. Reason: firebase_dart always applies '
        'transaction deltas locally before broadcasting the change.',
      );
    }
    // firebase_dart's TransactionHandler returns FutureOr<MutableData?>:
    //   return null           => abort
    //   return mutated data   => commit
    // fd.Transaction.abort / .success are NOT public factories in 1.6.2.
    final fd.TransactionResult result =
        await _reference.runTransaction((fd.MutableData data) {
      final Transaction tx = transactionHandler(data.value);
      if (tx.aborted) {
        return null;
      }
      data.value = tx.value;
      return data;
    });
    return _TizenTransactionResult(
      committed: result.committed,
      snapshot: result.dataSnapshot == null
          ? null
          : DataSnapshotTizen(
              _database,
              result.dataSnapshot!,
              reference: this,
            ),
    );
  }
}

/// Tizen [TransactionResultPlatform] holder — upstream's constructor only
/// accepts a `committed` bool; the snapshot is an abstract getter that
/// subclasses must provide.
class _TizenTransactionResult extends TransactionResultPlatform {
  _TizenTransactionResult({required bool committed, this._snapshot})
      : super(committed);

  final DataSnapshotPlatform? _snapshot;

  @override
  DataSnapshotPlatform get snapshot {
    final DataSnapshotPlatform? snap = _snapshot;
    if (snap == null) {
      throw StateError(
        'Transaction did not commit; snapshot is unavailable.',
      );
    }
    return snap;
  }
}
