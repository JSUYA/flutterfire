// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import 'reference_tizen.dart';
import 'storage_rest_client.dart';

/// Snapshot emitted by [TaskTizen.snapshotEvents] and [TaskTizen.onComplete].
class TaskSnapshotTizen extends TaskSnapshotPlatform {
  /// Creates a snapshot summarising the current transfer state.
  TaskSnapshotTizen({
    required this.bytesTransferred,
    required this.totalBytes,
    required ReferenceTizen ref,
    required TaskState state,
    this.downloadUrl,
    FullMetadata? metadata,
  })  : _ref = ref,
        _metadata = metadata,
        // TaskSnapshotPlatform(super) takes Map<String, dynamic>, not
        // Map<String, Object?>. Generics are invariant in Dart.
        super(state, <String, dynamic>{
          'bytesTransferred': bytesTransferred,
          'totalBytes': totalBytes,
        });

  final ReferenceTizen _ref;
  final FullMetadata? _metadata;

  @override
  final int bytesTransferred;

  @override
  final int totalBytes;

  /// Download URL assigned by the final snapshot of a successful upload.
  final String? downloadUrl;

  @override
  FullMetadata? get metadata => _metadata;

  @override
  ReferencePlatform get ref => _ref;
}

/// Tizen implementation of [TaskPlatform].
class TaskTizen extends TaskPlatform {
  /// Creates an upload task scaffolded around [_driver].
  TaskTizen._({
    required this.reference,
    required _TaskDriver driver,
  }) : _driver = driver {
    _driver.start();
  }

  /// Factory for simple data uploads.
  factory TaskTizen.upload({
    required ReferenceTizen reference,
    required StorageRestClient client,
    required Uint8List data,
    SettableMetadata? metadata,
  }) {
    return TaskTizen._(
      reference: reference,
      driver: _UploadDriver(
        reference: reference,
        client: client,
        path: reference.fullPath,
        dataSource: Stream<List<int>>.value(data),
        totalBytes: data.length,
        metadata: metadata,
      ),
    );
  }

  /// Factory for streamed uploads (files, resumable).
  factory TaskTizen.streamUpload({
    required ReferenceTizen reference,
    required StorageRestClient client,
    required Stream<List<int>> source,
    required int totalBytes,
    SettableMetadata? metadata,
  }) {
    return TaskTizen._(
      reference: reference,
      driver: _UploadDriver(
        reference: reference,
        client: client,
        path: reference.fullPath,
        dataSource: source,
        totalBytes: totalBytes,
        metadata: metadata,
      ),
    );
  }

  /// Factory for download tasks.
  factory TaskTizen.download({
    required ReferenceTizen reference,
    required StorageRestClient client,
    required StreamSink<List<int>> sink,
  }) {
    return TaskTizen._(
      reference: reference,
      driver: _DownloadDriver(
        reference: reference,
        client: client,
        path: reference.fullPath,
        sink: sink,
      ),
    );
  }

  /// The reference this task acts on.
  final ReferenceTizen reference;
  final _TaskDriver _driver;

  @override
  TaskSnapshotPlatform get snapshot => _driver.currentSnapshot;

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents => _driver.snapshotEvents;

  @override
  Future<TaskSnapshotPlatform> get onComplete => _driver.onComplete;

  @override
  Future<bool> cancel() async => _driver.cancel();

  @override
  Future<bool> pause() {
    throw UnimplementedError(
      'TaskPlatform.pause is not supported by firebase_storage_tizen. '
      'Reason: pause/resume state machines require an on-device transfer '
      'manager that this pure-Dart implementation does not provide.',
    );
  }

  @override
  Future<bool> resume() {
    throw UnimplementedError(
      'TaskPlatform.resume is not supported by firebase_storage_tizen.',
    );
  }
}

abstract class _TaskDriver {
  _TaskDriver({required this.reference});

  final ReferenceTizen reference;
  final StreamController<TaskSnapshotPlatform> _events =
      StreamController<TaskSnapshotPlatform>.broadcast();
  final Completer<TaskSnapshotPlatform> _completer =
      Completer<TaskSnapshotPlatform>();
  bool _cancelled = false;

  Stream<TaskSnapshotPlatform> get snapshotEvents => _events.stream;
  Future<TaskSnapshotPlatform> get onComplete => _completer.future;
  TaskSnapshotPlatform get currentSnapshot;

  /// Schedules the driver to begin work on the next microtask so constructors
  /// return immediately.
  void start() {
    scheduleMicrotask(_run);
  }

  Future<void> _run();

  Future<bool> cancel() async {
    if (_completer.isCompleted) {
      return false;
    }
    _cancelled = true;
    return true;
  }

  void _emit(TaskSnapshotPlatform snapshot, {bool done = false}) {
    if (!_events.isClosed) {
      _events.add(snapshot);
    }
    if (done && !_completer.isCompleted) {
      _completer.complete(snapshot);
      _events.close();
    }
  }

  void _fail(Object error, StackTrace stack) {
    if (_completer.isCompleted) {
      return;
    }
    _events.addError(error, stack);
    _completer.completeError(error, stack);
    _events.close();
  }

  bool get isCancelled => _cancelled;
}

class _UploadDriver extends _TaskDriver {
  _UploadDriver({
    required super.reference,
    required this.client,
    required this.path,
    required this.dataSource,
    required this.totalBytes,
    this.metadata,
  }) : _snapshot = TaskSnapshotTizen(
          bytesTransferred: 0,
          totalBytes: totalBytes,
          ref: reference,
          state: TaskState.running,
        );

  final StorageRestClient client;
  final String path;
  final Stream<List<int>> dataSource;
  final int totalBytes;
  final SettableMetadata? metadata;
  TaskSnapshotTizen _snapshot;

  @override
  TaskSnapshotPlatform get currentSnapshot => _snapshot;

  @override
  Future<void> _run() async {
    try {
      final List<int> buffer = <int>[];
      if (totalBytes <= kResumableUploadThresholdBytes) {
        await for (final List<int> chunk in dataSource) {
          if (isCancelled) {
            _emitCanceled();
            return;
          }
          buffer.addAll(chunk);
          _snapshot = _progress(buffer.length);
          _emit(_snapshot);
        }
        final Map<String, Object?> response = await client.uploadMultipart(
          path: path,
          data: buffer,
          metadata: metadata?.asMap(),
        );
        await _complete(response, buffer.length);
      } else {
        await _runResumable();
      }
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  Future<void> _runResumable() async {
    final Uri sessionUri = await client.startResumable(
      path: path,
      totalBytes: totalBytes,
      contentType: metadata?.contentType ?? 'application/octet-stream',
      metadata: metadata?.asMap(),
    );
    int offset = 0;
    final List<int> pending = <int>[];
    Map<String, Object?>? finalResponse;
    await for (final List<int> chunk in dataSource) {
      if (isCancelled) {
        _emitCanceled();
        return;
      }
      pending.addAll(chunk);
      while (pending.length >= kResumableChunkSizeBytes) {
        final List<int> slice =
            pending.sublist(0, kResumableChunkSizeBytes);
        pending.removeRange(0, kResumableChunkSizeBytes);
        await client.uploadChunk(
          sessionUri: sessionUri,
          chunk: slice,
          byteOffset: offset,
          totalBytes: totalBytes,
          isFinal: false,
        );
        offset += slice.length;
        _snapshot = _progress(offset);
        _emit(_snapshot);
      }
    }
    if (isCancelled) {
      _emitCanceled();
      return;
    }
    finalResponse = await client.uploadChunk(
      sessionUri: sessionUri,
      chunk: pending,
      byteOffset: offset,
      totalBytes: totalBytes,
      isFinal: true,
    );
    offset += pending.length;
    await _complete(finalResponse ?? <String, Object?>{}, offset);
  }

  Future<void> _complete(Map<String, Object?> response, int bytes) async {
    final FullMetadata meta =
        FullMetadata(Map<String, dynamic>.from(response));
    _snapshot = TaskSnapshotTizen(
      bytesTransferred: bytes,
      totalBytes: totalBytes,
      ref: reference,
      state: TaskState.success,
      metadata: meta,
    );
    _emit(_snapshot, done: true);
  }

  TaskSnapshotTizen _progress(int transferred) {
    return TaskSnapshotTizen(
      bytesTransferred: transferred,
      totalBytes: totalBytes,
      ref: reference,
      state: TaskState.running,
    );
  }

  void _emitCanceled() {
    _snapshot = TaskSnapshotTizen(
      bytesTransferred: _snapshot.bytesTransferred,
      totalBytes: totalBytes,
      ref: reference,
      state: TaskState.canceled,
    );
    _emit(_snapshot, done: true);
  }
}

class _DownloadDriver extends _TaskDriver {
  _DownloadDriver({
    required super.reference,
    required this.client,
    required this.path,
    required this.sink,
  }) : _snapshot = TaskSnapshotTizen(
          bytesTransferred: 0,
          totalBytes: 0,
          ref: reference,
          state: TaskState.running,
        );

  final StorageRestClient client;
  final String path;
  final StreamSink<List<int>> sink;
  TaskSnapshotTizen _snapshot;

  @override
  TaskSnapshotPlatform get currentSnapshot => _snapshot;

  @override
  Future<void> _run() async {
    int bytes = 0;
    try {
      bytes = await client.download(path, sink);
      _snapshot = TaskSnapshotTizen(
        bytesTransferred: bytes,
        totalBytes: bytes,
        ref: reference,
        state: TaskState.success,
      );
      _emit(_snapshot, done: true);
    } catch (error, stack) {
      _fail(error, stack);
    } finally {
      // Always close the sink, even on error, so the underlying
      // IOSink / file handle doesn't leak. download() may throw
      // mid-stream (network drop, maxSize exceeded).
      try {
        await sink.close();
      } catch (_) {
        // Secondary close failures are intentionally swallowed — the
        // primary exception is already propagated through _fail.
      }
    }
  }
}

extension on SettableMetadata {
  Map<String, Object?> asMap() {
    return <String, Object?>{
      if (contentType != null) 'contentType': contentType,
      if (contentLanguage != null) 'contentLanguage': contentLanguage,
      if (contentEncoding != null) 'contentEncoding': contentEncoding,
      if (contentDisposition != null) 'contentDisposition': contentDisposition,
      if (cacheControl != null) 'cacheControl': cacheControl,
      if (customMetadata != null) 'metadata': customMetadata,
    };
  }
}
