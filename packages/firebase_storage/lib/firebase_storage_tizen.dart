// ignore_for_file: prefer_final_parameters

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart'
    show FirebaseTizenRuntime;
import 'package:firebase_dart/firebase_dart.dart' as firebase_dart;
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

/// Tizen implementation of [FirebaseStoragePlatform].
class FirebaseStorageTizen extends FirebaseStoragePlatform {
  /// Creates a storage platform instance.
  FirebaseStorageTizen({super.appInstance, required super.bucket});

  /// Registers this implementation as the default storage platform.
  static void register() {
    FirebaseStoragePlatform.instance = FirebaseStorageTizen(bucket: '');
  }

  int _maxOperationRetryTime = const Duration(minutes: 2).inMilliseconds;
  int _maxUploadRetryTime = const Duration(minutes: 10).inMilliseconds;
  int _maxDownloadRetryTime = const Duration(minutes: 10).inMilliseconds;

  firebase_dart.FirebaseStorage _storage() {
    final FirebaseApp resolvedApp = app;
    final firebase_dart.FirebaseApp dartApp =
        FirebaseTizenRuntime.dartAppForPublicApp(resolvedApp);
    return firebase_dart.FirebaseStorage.instanceFor(
      app: dartApp,
      bucket: bucket,
    );
  }

  @override
  FirebaseStoragePlatform delegateFor({
    required FirebaseApp app,
    required String bucket,
  }) {
    return FirebaseStorageTizen(appInstance: app, bucket: bucket)
      ..emulatorHost = emulatorHost
      ..emulatorPort = emulatorPort
      .._maxDownloadRetryTime = _maxDownloadRetryTime
      .._maxOperationRetryTime = _maxOperationRetryTime
      .._maxUploadRetryTime = _maxUploadRetryTime;
  }

  @override
  int get maxDownloadRetryTime => _maxDownloadRetryTime;

  @override
  int get maxOperationRetryTime => _maxOperationRetryTime;

  @override
  int get maxUploadRetryTime => _maxUploadRetryTime;

  @override
  ReferencePlatform ref(String path) {
    return _ReferenceTizen(storage: this, delegate: _storage().ref(path));
  }

  @override
  void setMaxDownloadRetryTime(int time) {
    _maxDownloadRetryTime = time;
  }

  @override
  void setMaxOperationRetryTime(int time) {
    _maxOperationRetryTime = time;
    _storage().setMaxOperationRetryTime(Duration(milliseconds: time));
  }

  @override
  void setMaxUploadRetryTime(int time) {
    _maxUploadRetryTime = time;
    _storage().setMaxUploadRetryTime(Duration(milliseconds: time));
  }

  @override
  Future<void> useStorageEmulator(String host, int port) async {
    emulatorHost = host;
    emulatorPort = port;
    throw UnimplementedError(
      'Cloud Storage emulator is not supported on Tizen yet.',
    );
  }
}

class _ReferenceTizen extends ReferencePlatform {
  _ReferenceTizen({
    required FirebaseStorageTizen storage,
    required this.delegate,
  }) : super(storage, delegate.fullPath.isEmpty ? '/' : delegate.fullPath);

  final firebase_dart.Reference delegate;

  @override
  Future<void> delete() async {
    await FirebaseTizenRuntime.ensureInitialized();
    try {
      await delegate.delete();
    } on firebase_dart.FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  @override
  Future<Uint8List?> getData(int maxSize) async {
    await FirebaseTizenRuntime.ensureInitialized();
    try {
      return await delegate.getData(maxSize);
    } on firebase_dart.FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  @override
  Future<String> getDownloadURL() async {
    await FirebaseTizenRuntime.ensureInitialized();
    try {
      return await delegate.getDownloadURL();
    } on firebase_dart.FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  @override
  Future<FullMetadata> getMetadata() async {
    await FirebaseTizenRuntime.ensureInitialized();
    try {
      return _toFullMetadata(await delegate.getMetadata());
    } on firebase_dart.FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  @override
  Future<ListResultPlatform> list([ListOptions? options]) async {
    await FirebaseTizenRuntime.ensureInitialized();
    try {
      return _ListResultTizen(
        storage: storage,
        delegate: await delegate.list(
          options == null
              ? null
              : firebase_dart.ListOptions(
                  maxResults: options.maxResults,
                  pageToken: options.pageToken,
                ),
        ),
      );
    } on firebase_dart.FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  @override
  Future<ListResultPlatform> listAll() async {
    await FirebaseTizenRuntime.ensureInitialized();
    try {
      return _ListResultTizen(
        storage: storage,
        delegate: await delegate.listAll(),
      );
    } on firebase_dart.FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  @override
  TaskPlatform putBlob(dynamic data, [SettableMetadata? metadata]) {
    throw UnimplementedError(
      'putBlob() is not supported on native platforms. Use [put], [putFile] or [putString] instead.',
    );
  }

  @override
  TaskPlatform putData(Uint8List data, [SettableMetadata? metadata]) {
    final firebase_dart.UploadTask task = delegate.putData(
      data,
      _toSettableMetadata(metadata),
    );
    return _UploadTaskTizen(delegate: task, ref: this);
  }

  @override
  TaskPlatform putFile(File file, [SettableMetadata? metadata]) {
    final Uint8List data = file.readAsBytesSync();
    final firebase_dart.UploadTask task = delegate.putData(
      data,
      _toSettableMetadata(metadata),
    );
    return _UploadTaskTizen(delegate: task, ref: this);
  }

  @override
  TaskPlatform putString(
    String data,
    PutStringFormat format, [
    SettableMetadata? metadata,
  ]) {
    final firebase_dart.UploadTask task = delegate.putString(
      data,
      format: _toPutStringFormat(format),
      metadata: _toSettableMetadata(metadata),
    );
    return _UploadTaskTizen(delegate: task, ref: this);
  }

  @override
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    await FirebaseTizenRuntime.ensureInitialized();
    try {
      return _toFullMetadata(
        await delegate.updateMetadata(_toSettableMetadata(metadata)!),
      );
    } on firebase_dart.FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_translateError(error), stackTrace);
    }
  }

  @override
  TaskPlatform writeToFile(File file) {
    return _DownloadTaskTizen(ref: this, file: file);
  }

  firebase_dart.SettableMetadata? _toSettableMetadata(
    SettableMetadata? metadata,
  ) {
    if (metadata == null) {
      return null;
    }
    return firebase_dart.SettableMetadata(
      cacheControl: metadata.cacheControl,
      contentDisposition: metadata.contentDisposition,
      contentEncoding: metadata.contentEncoding,
      contentLanguage: metadata.contentLanguage,
      contentType: metadata.contentType,
      customMetadata: metadata.customMetadata,
    );
  }

  firebase_dart.PutStringFormat _toPutStringFormat(PutStringFormat format) {
    switch (format) {
      case PutStringFormat.base64:
        return firebase_dart.PutStringFormat.base64;
      case PutStringFormat.base64Url:
        return firebase_dart.PutStringFormat.base64Url;
      case PutStringFormat.dataUrl:
        return firebase_dart.PutStringFormat.dataUrl;
      case PutStringFormat.raw:
        return firebase_dart.PutStringFormat.raw;
    }
  }

  FullMetadata _toFullMetadata(firebase_dart.FullMetadata metadata) {
    return FullMetadata(<String, dynamic>{
      'bucket': metadata.bucket,
      'cacheControl': metadata.cacheControl,
      'contentDisposition': metadata.contentDisposition,
      'contentEncoding': metadata.contentEncoding,
      'contentLanguage': metadata.contentLanguage,
      'contentType': metadata.contentType,
      'creationTimeMillis': metadata.timeCreated?.millisecondsSinceEpoch,
      'customMetadata': metadata.customMetadata,
      'fullPath': metadata.fullPath,
      'generation': metadata.generation,
      'md5Hash': metadata.md5Hash,
      'metadataGeneration': metadata.metadataGeneration,
      'metageneration': metadata.metageneration,
      'name': metadata.name,
      'size': metadata.size,
      'updatedTimeMillis': metadata.updated?.millisecondsSinceEpoch,
    });
  }

  FirebaseException _translateError(firebase_dart.FirebaseException error) {
    return FirebaseException(
      plugin: 'firebase_storage',
      code: error.code,
      message: error.message,
    );
  }
}

class _ListResultTizen extends ListResultPlatform {
  _ListResultTizen({
    required FirebaseStoragePlatform? storage,
    required this.delegate,
  }) : super(storage, delegate.nextPageToken);

  final firebase_dart.ListResult delegate;

  @override
  List<ReferencePlatform> get items {
    return delegate.items
        .map<ReferencePlatform>(
          (firebase_dart.Reference reference) => _ReferenceTizen(
            storage: storage! as FirebaseStorageTizen,
            delegate: reference,
          ),
        )
        .toList(growable: false);
  }

  @override
  List<ReferencePlatform> get prefixes {
    return delegate.prefixes
        .map<ReferencePlatform>(
          (firebase_dart.Reference reference) => _ReferenceTizen(
            storage: storage! as FirebaseStorageTizen,
            delegate: reference,
          ),
        )
        .toList(growable: false);
  }
}

class _UploadTaskTizen extends TaskPlatform {
  _UploadTaskTizen({required this.delegate, required this.ref});

  final firebase_dart.UploadTask delegate;
  final _ReferenceTizen ref;

  @override
  Future<bool> cancel() => delegate.cancel();

  @override
  Future<TaskSnapshotPlatform> get onComplete async {
    final firebase_dart.TaskSnapshot snapshot = await delegate;
    return _TaskSnapshotTizen(snapshot: snapshot, ref: ref);
  }

  @override
  Future<bool> pause() => delegate.pause();

  @override
  Future<bool> resume() => delegate.resume();

  @override
  TaskSnapshotPlatform get snapshot {
    return _TaskSnapshotTizen(snapshot: delegate.snapshot, ref: ref);
  }

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return delegate.snapshotEvents.map<TaskSnapshotPlatform>(
      (firebase_dart.TaskSnapshot snapshot) =>
          _TaskSnapshotTizen(snapshot: snapshot, ref: ref),
    );
  }
}

class _DownloadTaskTizen extends TaskPlatform {
  _DownloadTaskTizen({required this.ref, required this.file}) {
    _start();
  }

  final _ReferenceTizen ref;
  final File file;
  final StreamController<TaskSnapshotPlatform> _controller =
      StreamController<TaskSnapshotPlatform>.broadcast();
  final Completer<TaskSnapshotPlatform> _completer =
      Completer<TaskSnapshotPlatform>();

  TaskState _state = TaskState.running;
  int _bytesTransferred = 0;
  int _totalBytes = -1;

  void _start() {
    unawaited(_runDownload());
  }

  Future<void> _runDownload() async {
    try {
      await FirebaseTizenRuntime.ensureInitialized();
      final Uint8List? data = await ref.delegate.getData(1 << 31);
      if (data == null) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'unknown',
          message: 'Download returned no data.',
        );
      }
      _totalBytes = data.length;
      await file.writeAsBytes(data);
      _bytesTransferred = data.length;
      _state = TaskState.success;
      final TaskSnapshotPlatform snapshot = _snapshot();
      _controller.add(snapshot);
      await _controller.close();
      _completer.complete(snapshot);
    } catch (error, stackTrace) {
      _state = TaskState.error;
      await _controller.close();
      _completer.completeError(error, stackTrace);
    }
  }

  TaskSnapshotPlatform _snapshot() {
    return _TaskSnapshotTizen.fromValues(
      ref: ref,
      state: _state,
      bytesTransferred: _bytesTransferred,
      totalBytes: _totalBytes,
      metadata: null,
    );
  }

  @override
  Future<bool> cancel() async => false;

  @override
  Future<TaskSnapshotPlatform> get onComplete => _completer.future;

  @override
  Future<bool> pause() async => false;

  @override
  Future<bool> resume() async => false;

  @override
  TaskSnapshotPlatform get snapshot => _snapshot();

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents => _controller.stream;
}

class _TaskSnapshotTizen extends TaskSnapshotPlatform {
  _TaskSnapshotTizen({
    required firebase_dart.TaskSnapshot snapshot,
    required _ReferenceTizen ref,
  }) : this.fromValues(
          ref: ref,
          state: _toTaskState(snapshot.state),
          bytesTransferred: snapshot.bytesTransferred,
          totalBytes: snapshot.totalBytes,
          metadata: snapshot.metadata == null
              ? null
              : ref._toFullMetadata(snapshot.metadata!),
        );

  _TaskSnapshotTizen.fromValues({
    required this.ref,
    required TaskState state,
    required int bytesTransferred,
    required int totalBytes,
    required FullMetadata? metadata,
  }) : super(state, <String, dynamic>{
          'bytesTransferred': bytesTransferred,
          'metadata': metadata == null ? null : _metadataToMap(metadata),
          'totalBytes': totalBytes,
        });

  @override
  final ReferencePlatform ref;

  static Map<String, dynamic> _metadataToMap(FullMetadata metadata) {
    return <String, dynamic>{
      'bucket': metadata.bucket,
      'cacheControl': metadata.cacheControl,
      'contentDisposition': metadata.contentDisposition,
      'contentEncoding': metadata.contentEncoding,
      'contentLanguage': metadata.contentLanguage,
      'contentType': metadata.contentType,
      'creationTimeMillis': metadata.timeCreated?.millisecondsSinceEpoch,
      'customMetadata': metadata.customMetadata,
      'fullPath': metadata.fullPath,
      'generation': metadata.generation,
      'md5Hash': metadata.md5Hash,
      'metadataGeneration': metadata.metadataGeneration,
      'metageneration': metadata.metageneration,
      'name': metadata.name,
      'size': metadata.size,
      'updatedTimeMillis': metadata.updated?.millisecondsSinceEpoch,
    };
  }

  static TaskState _toTaskState(firebase_dart.TaskState state) {
    switch (state) {
      case firebase_dart.TaskState.paused:
        return TaskState.paused;
      case firebase_dart.TaskState.running:
        return TaskState.running;
      case firebase_dart.TaskState.success:
        return TaskState.success;
      case firebase_dart.TaskState.canceled:
        return TaskState.canceled;
      case firebase_dart.TaskState.error:
        return TaskState.error;
    }
  }
}
