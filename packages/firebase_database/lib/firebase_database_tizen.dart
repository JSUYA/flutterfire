import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart'
    show FirebaseTizenRuntime;
import 'package:firebase_dart/firebase_dart.dart' as firebase_dart;
import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';

/// Tizen implementation of [DatabasePlatform] backed by `firebase_dart`.
class FirebaseDatabaseTizen extends DatabasePlatform {
  /// Creates a database platform instance.
  FirebaseDatabaseTizen({super.app, super.databaseURL});

  /// Registers this implementation as the default database platform.
  static void register() {
    DatabasePlatform.instance = FirebaseDatabaseTizen();
  }

  String? _emulatorHost;
  int? _emulatorPort;

  firebase_dart.FirebaseDatabase _database() {
    final FirebaseApp resolvedApp = app ?? Firebase.app();
    final firebase_dart.FirebaseApp dartApp =
        FirebaseTizenRuntime.dartAppForPublicApp(resolvedApp);
    return firebase_dart.FirebaseDatabase(
      app: dartApp,
      databaseURL: _resolvedDatabaseUrl(resolvedApp),
    );
  }

  String _resolvedDatabaseUrl(FirebaseApp resolvedApp) {
    if (_emulatorHost == null || _emulatorPort == null) {
      return databaseURL ?? resolvedApp.options.databaseURL!;
    }

    final Uri source = Uri.parse(
      databaseURL ?? resolvedApp.options.databaseURL!,
    );
    final String ns = source.queryParameters['ns'] ??
        source.host.split('.').firstWhere(
              (String segment) => segment.isNotEmpty,
              orElse: () => resolvedApp.options.projectId,
            );

    return Uri(
      scheme: 'http',
      host: _emulatorHost,
      port: _emulatorPort,
      queryParameters: <String, String>{'ns': ns},
    ).toString();
  }

  @override
  DatabasePlatform delegateFor({
    required FirebaseApp app,
    String? databaseURL,
  }) {
    return FirebaseDatabaseTizen(app: app, databaseURL: databaseURL)
      .._emulatorHost = _emulatorHost
      .._emulatorPort = _emulatorPort;
  }

  @override
  Map<String, Object?> getChannelArguments([Map<String, Object?>? other]) {
    return <String, Object?>{
      'appName': app?.name ?? defaultFirebaseAppName,
      'databaseURL': databaseURL,
      ...?other,
    };
  }

  @override
  Future<void> goOffline() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _database().goOffline();
  }

  @override
  Future<void> goOnline() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _database().goOnline();
  }

  @override
  Future<void> purgeOutstandingWrites() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _database().purgeOutstandingWrites();
  }

  @override
  DatabaseReferencePlatform ref([String? path]) {
    final firebase_dart.DatabaseReference reference = path == null
        ? _database().reference()
        : _database().reference().child(path);
    return _DatabaseReferenceTizen(database: this, reference: reference);
  }

  @override
  void setLoggingEnabled(bool enabled) {}

  @override
  void setPersistenceCacheSizeBytes(int cacheSize) {
    unawaited(_database().setPersistenceCacheSizeBytes(cacheSize));
  }

  @override
  void setPersistenceEnabled(bool enabled) {
    unawaited(_database().setPersistenceEnabled(enabled));
  }

  @override
  void useDatabaseEmulator(String host, int port) {
    _emulatorHost = host;
    _emulatorPort = port;
  }
}

class _DatabaseReferenceTizen extends QueryPlatform
    implements DatabaseReferencePlatform {
  _DatabaseReferenceTizen({
    required this.reference,
    required FirebaseDatabaseTizen database,
  })  : _database = database,
        super(database: database);

  final FirebaseDatabaseTizen _database;
  final firebase_dart.DatabaseReference reference;

  @override
  String? get key => reference.key;

  @override
  DatabaseReferencePlatform child(String path) {
    return _DatabaseReferenceTizen(
      database: _database,
      reference: reference.child(path),
    );
  }

  @override
  OnDisconnectPlatform onDisconnect() {
    return _OnDisconnectTizen(database: _database, ref: this);
  }

  @override
  DatabaseReferencePlatform? get parent {
    final firebase_dart.DatabaseReference? parentReference = reference.parent();
    if (parentReference == null) {
      return null;
    }
    return _DatabaseReferenceTizen(
      database: _database,
      reference: parentReference,
    );
  }

  @override
  String get path => reference.path;

  @override
  DatabaseReferencePlatform push() {
    return _DatabaseReferenceTizen(
      database: _database,
      reference: reference.push(),
    );
  }

  @override
  Future<void> remove() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await reference.remove();
  }

  @override
  DatabaseReferencePlatform get ref => this;

  @override
  DatabaseReferencePlatform root() {
    return _DatabaseReferenceTizen(
      database: _database,
      reference: reference.root(),
    );
  }

  @override
  Future<TransactionResultPlatform> runTransaction(
    TransactionHandler transactionHandler, {
    bool applyLocally = true,
  }) async {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.TransactionResult result =
        await reference.runTransaction((firebase_dart.MutableData mutableData) {
      final Transaction transaction = transactionHandler(mutableData.value);
      if (transaction.aborted) {
        return null;
      }

      mutableData.value = transaction.value;
      return mutableData;
    });

    return _TransactionResultTizen(
      committed: result.committed,
      snapshot: _DataSnapshotTizen(ref: this, snapshot: result.dataSnapshot),
    );
  }

  @override
  Future<void> set(Object? value) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await reference.set(value);
  }

  @override
  Future<void> setPriority(Object? priority) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await reference.setPriority(priority);
  }

  @override
  Future<void> setWithPriority(Object? value, Object? priority) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await reference.set(value, priority: priority);
  }

  @override
  Future<void> update(Map<String, Object?> value) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await reference.update(value);
  }

  @override
  Future<void> keepSynced(QueryModifiers modifiers, bool value) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _applyModifiers(reference, modifiers).keepSynced(value);
  }

  @override
  Future<DataSnapshotPlatform> get(QueryModifiers modifiers) async {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.DataSnapshot snapshot = await _applyModifiers(
      reference,
      modifiers,
    ).once();
    return _DataSnapshotTizen(ref: this, snapshot: snapshot);
  }

  @override
  Stream<DatabaseEventPlatform> observe(
    QueryModifiers modifiers,
    DatabaseEventType eventType,
  ) async* {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.Query query = _applyModifiers(reference, modifiers);

    yield* query.on(_eventTypeName(eventType)).transform<DatabaseEventPlatform>(
          StreamTransformer<firebase_dart.Event,
              DatabaseEventPlatform>.fromHandlers(
            handleData: (
              firebase_dart.Event event,
              EventSink<DatabaseEventPlatform> sink,
            ) {
              sink.add(
                _DatabaseEventTizen(
                  data: <String, dynamic>{
                    'eventType': eventTypeToString(eventType),
                    'previousChildKey': event.previousSiblingKey,
                  },
                  snapshot: _DataSnapshotTizen(
                    ref: _DatabaseReferenceTizen(
                      database: _database,
                      reference: event.snapshot.key == null
                          ? reference
                          : reference.child(event.snapshot.key!),
                    ),
                    snapshot: event.snapshot,
                  ),
                ),
              );
            },
            handleError: (
              Object error,
              StackTrace stackTrace,
              EventSink<DatabaseEventPlatform> sink,
            ) {
              sink.addError(_translateError(error), stackTrace);
            },
          ),
        );
  }

  firebase_dart.Query _applyModifiers(
    firebase_dart.Query query,
    QueryModifiers modifiers,
  ) {
    firebase_dart.Query current = query;
    for (final QueryModifier modifier in modifiers.toIterable()) {
      switch (modifier) {
        case OrderModifier order:
          current = _applyOrder(current, order);
        case StartCursorModifier start:
          current = current.startAt(start.value, key: start.key);
        case EndCursorModifier end:
          current = current.endAt(end.value, key: end.key);
        case LimitModifier limit:
          current = limit.name == 'limitToFirst'
              ? current.limitToFirst(limit.value)
              : current.limitToLast(limit.value);
        default:
          break;
      }
    }
    return current;
  }

  firebase_dart.Query _applyOrder(
    firebase_dart.Query query,
    OrderModifier modifier,
  ) {
    switch (modifier.name) {
      case 'orderByChild':
        return query.orderByChild(modifier.path!);
      case 'orderByKey':
        return query.orderByKey();
      case 'orderByValue':
        return query.orderByValue();
      case 'orderByPriority':
        return query.orderByPriority();
      default:
        return query;
    }
  }

  String _eventTypeName(DatabaseEventType eventType) {
    switch (eventType) {
      case DatabaseEventType.childAdded:
        return 'child_added';
      case DatabaseEventType.childRemoved:
        return 'child_removed';
      case DatabaseEventType.childChanged:
        return 'child_changed';
      case DatabaseEventType.childMoved:
        return 'child_moved';
      case DatabaseEventType.value:
        return 'value';
    }
  }

  FirebaseException _translateError(Object error) {
    if (error is firebase_dart.FirebaseDatabaseException) {
      return FirebaseException(
        plugin: 'firebase_database',
        code: error.code,
        message: error.message,
      );
    }

    return FirebaseException(
      plugin: 'firebase_database',
      code: 'unknown',
      message: error.toString(),
    );
  }
}

class _OnDisconnectTizen extends OnDisconnectPlatform {
  _OnDisconnectTizen({
    required FirebaseDatabaseTizen database,
    required _DatabaseReferenceTizen ref,
  })  : _ref = ref,
        super(database: database, ref: ref);

  final _DatabaseReferenceTizen _ref;

  firebase_dart.OnDisconnect get _delegate => _ref.reference.onDisconnect();

  @override
  Future<void> cancel() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _delegate.cancel();
  }

  @override
  Future<void> set(Object? value) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _delegate.set(value);
  }

  @override
  Future<void> setWithPriority(Object? value, Object? priority) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _delegate.set(value, priority: priority);
  }

  @override
  Future<void> update(Map<String, Object?> value) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _delegate.update(value);
  }
}

class _DataSnapshotTizen extends DataSnapshotPlatform {
  _DataSnapshotTizen({
    required DatabaseReferencePlatform ref,
    required firebase_dart.DataSnapshot? snapshot,
  }) : super(ref, <String, dynamic>{
          'key': snapshot?.key,
          'priority': null,
          'value': snapshot?.value,
        });

  @override
  DataSnapshotPlatform child(String childPath) {
    final Object? childValue = _childValue(value, childPath);
    return _DataSnapshotTizen(
      ref: ref.child(childPath),
      snapshot: _SyntheticDataSnapshot(
        key: childPath.split('/').last,
        value: childValue,
      ),
    );
  }

  @override
  Iterable<DataSnapshotPlatform> get children sync* {
    final Object? currentValue = value;
    if (currentValue is Map<Object?, Object?>) {
      for (final MapEntry<Object?, Object?> entry in currentValue.entries) {
        yield child(entry.key.toString());
      }
      return;
    }
    if (currentValue is List<Object?>) {
      for (int index = 0; index < currentValue.length; index += 1) {
        if (currentValue[index] != null) {
          yield child(index.toString());
        }
      }
    }
  }

  Object? _childValue(Object? current, String childPath) {
    Object? valueAtPath = current;
    for (final String segment in childPath.split('/')) {
      if (valueAtPath is Map<Object?, Object?>) {
        valueAtPath = valueAtPath[segment];
      } else if (valueAtPath is List<Object?>) {
        final int? index = int.tryParse(segment);
        valueAtPath = index == null || index >= valueAtPath.length
            ? null
            : valueAtPath[index];
      } else {
        return null;
      }
    }
    return valueAtPath;
  }
}

class _DatabaseEventTizen extends DatabaseEventPlatform {
  _DatabaseEventTizen({
    required Map<String, dynamic> data,
    required DataSnapshotPlatform snapshot,
  })  : _snapshot = snapshot,
        super(data);

  final DataSnapshotPlatform _snapshot;

  @override
  DataSnapshotPlatform get snapshot => _snapshot;
}

class _TransactionResultTizen extends TransactionResultPlatform {
  _TransactionResultTizen({
    required bool committed,
    required DataSnapshotPlatform snapshot,
  })  : _snapshot = snapshot,
        super(committed);

  final DataSnapshotPlatform _snapshot;

  @override
  DataSnapshotPlatform get snapshot => _snapshot;
}

class _SyntheticDataSnapshot implements firebase_dart.DataSnapshot {
  _SyntheticDataSnapshot({required this.key, required this.value});

  @override
  final String? key;

  @override
  final Object? value;
}
