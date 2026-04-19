// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:path/path.dart' as p;

import 'firebase_storage_tizen_impl.dart';
import 'storage_rest_client.dart';
import 'task_tizen.dart';

/// Tizen [ReferencePlatform] delegate.
class ReferenceTizen extends ReferencePlatform {
  /// Creates a reference rooted at [fullPath] inside [storage].
  ReferenceTizen(
    FirebaseStorageTizen storage,
    String fullPath,
  )   : _storage = storage,
        _client = storage.client,
        super(storage, fullPath);

  /// Internal constructor used by [TaskTizen] when it does not yet know the
  /// concrete reference (pre-bind).
  ReferenceTizen.unassigned()
      : _storage = null,
        _client = null,
        super.unassigned();

  final FirebaseStorageTizen? _storage;
  final StorageRestClient? _client;

  FirebaseStorageTizen get _requireStorage {
    final FirebaseStorageTizen? storage = _storage;
    if (storage == null) {
      throw StateError(
        'ReferenceTizen was used before it was bound to a FirebaseStorageTizen '
        'instance.',
      );
    }
    return storage;
  }

  StorageRestClient get _requireClient {
    final StorageRestClient? client = _client;
    if (client == null) {
      throw StateError(
        'ReferenceTizen was used before its REST client was assigned.',
      );
    }
    return client;
  }

  @override
  ReferencePlatform child(String path) {
    final String joined =
        p.posix.normalize(p.posix.join(fullPath, path));
    return ReferenceTizen(_requireStorage, joined);
  }

  @override
  ReferencePlatform? get parent {
    if (fullPath.isEmpty || fullPath == '/') {
      return null;
    }
    final String parentPath = p.posix.dirname(fullPath);
    return ReferenceTizen(
      _requireStorage,
      parentPath == '.' ? '' : parentPath,
    );
  }

  @override
  ReferencePlatform get root => ReferenceTizen(_requireStorage, '');

  @override
  Future<void> delete() => _requireClient.deleteObject(fullPath);

  @override
  Future<Uint8List?> getData(int maxSize) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    final StreamController<List<int>> controller =
        StreamController<List<int>>();
    final StreamSubscription<List<int>> subscription =
        controller.stream.listen(builder.add);
    try {
      await _requireClient.download(fullPath, controller.sink,
          maxSize: maxSize);
    } finally {
      await subscription.cancel();
      await controller.close();
    }
    return builder.takeBytes();
  }

  @override
  Future<String> getDownloadURL() =>
      _requireClient.getDownloadUrl(fullPath);

  @override
  Future<FullMetadata> getMetadata() async {
    final Map<String, Object?> raw =
        await _requireClient.getMetadata(fullPath);
    return FullMetadata(Map<String, dynamic>.from(raw));
  }

  @override
  Future<ListResultPlatform> list([ListOptions? options]) async {
    final Map<String, Object?> response = await _requireClient.list(
      prefix: fullPath.isEmpty ? null : '$fullPath/',
      pageToken: options?.pageToken,
      maxResults: options?.maxResults,
    );
    return _listResult(response);
  }

  @override
  Future<ListResultPlatform> listAll() async {
    final List<ReferencePlatform> items = <ReferencePlatform>[];
    final List<ReferencePlatform> prefixes = <ReferencePlatform>[];
    String? token;
    do {
      final Map<String, Object?> page = await _requireClient.list(
        prefix: fullPath.isEmpty ? null : '$fullPath/',
        pageToken: token,
      );
      final ListResultPlatform result = _listResult(page);
      items.addAll(result.items);
      prefixes.addAll(result.prefixes);
      token = result.nextPageToken;
    } while (token != null);
    return _ListResultTizen(
      _requireStorage,
      null,
      items: items,
      prefixes: prefixes,
    );
  }

  ListResultPlatform _listResult(Map<String, Object?> response) {
    final List<ReferencePlatform> items = <ReferencePlatform>[];
    final Object? objects = response['items'];
    if (objects is List) {
      for (final Object? entry in objects) {
        if (entry is Map<String, Object?>) {
          final String? name = entry['name'] as String?;
          if (name != null) {
            items.add(ReferenceTizen(_requireStorage, name));
          }
        }
      }
    }
    final List<ReferencePlatform> prefixes = <ReferencePlatform>[];
    final Object? rawPrefixes = response['prefixes'];
    if (rawPrefixes is List) {
      for (final Object? entry in rawPrefixes) {
        if (entry is String) {
          prefixes.add(ReferenceTizen(
            _requireStorage,
            entry.endsWith('/') ? entry.substring(0, entry.length - 1) : entry,
          ));
        }
      }
    }
    return _ListResultTizen(
      _requireStorage,
      response['nextPageToken'] as String?,
      items: items,
      prefixes: prefixes,
    );
  }

  @override
  TaskPlatform putBlob(Object data, [SettableMetadata? metadata]) {
    throw UnimplementedError(
      'putBlob is not supported by firebase_storage_tizen. Reason: Blob is a '
      'Web-only type; use putData (Uint8List) or putFile instead.',
    );
  }

  @override
  TaskPlatform putData(Uint8List data, [SettableMetadata? metadata]) {
    return TaskTizen.upload(
      reference: this,
      client: _requireClient,
      data: data,
      metadata: metadata,
    );
  }

  @override
  TaskPlatform putFile(File file, [SettableMetadata? metadata]) {
    final int totalBytes = file.lengthSync();
    return TaskTizen.streamUpload(
      reference: this,
      client: _requireClient,
      source: file.openRead(),
      totalBytes: totalBytes,
      metadata: metadata,
    );
  }

  @override
  TaskPlatform putString(
    String data,
    PutStringFormat format, [
    SettableMetadata? metadata,
  ]) {
    late Uint8List bytes;
    switch (format) {
      case PutStringFormat.raw:
        bytes = Uint8List.fromList(utf8.encode(data));
      case PutStringFormat.base64:
        bytes = base64Decode(data);
      case PutStringFormat.base64Url:
        bytes = base64Url.decode(data);
      case PutStringFormat.dataUrl:
        final int comma = data.indexOf(',');
        if (comma == -1) {
          throw ArgumentError.value(data, 'data', 'Missing data URL payload.');
        }
        bytes = base64Decode(data.substring(comma + 1));
    }
    return putData(bytes, metadata);
  }

  @override
  TaskPlatform writeToFile(File file) {
    final IOSink sink = file.openWrite();
    return TaskTizen.download(
      reference: this,
      client: _requireClient,
      sink: sink,
    );
  }

  @override
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    final Map<String, Object?> response =
        await _requireClient.updateMetadata(fullPath, metadata.asMap());
    return FullMetadata(Map<String, dynamic>.from(response));
  }
}

/// Tizen [ListResultPlatform] subclass that exposes `items` / `prefixes`
/// through the abstract getters the upstream platform interface defines.
///
/// The upstream `ListResultPlatform` constructor takes only
/// `(FirebaseStoragePlatform?, String? nextPageToken)`; `items` and
/// `prefixes` are abstract and must be provided by a subclass.
class _ListResultTizen extends ListResultPlatform {
  _ListResultTizen(
    FirebaseStoragePlatform? storage,
    String? nextPageToken, {
    required this.items,
    required this.prefixes,
  }) : super(storage, nextPageToken);

  @override
  final List<ReferencePlatform> items;

  @override
  final List<ReferencePlatform> prefixes;
}

extension _SettableMetadataAsMap on SettableMetadata {
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
