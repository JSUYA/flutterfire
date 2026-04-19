// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'storage_error_mapper.dart';

/// Chunk size for resumable uploads. 256 KiB matches the native SDK.
const int kResumableChunkSizeBytes = 256 * 1024;

/// Threshold above which uploads switch to the resumable protocol.
const int kResumableUploadThresholdBytes = 8 * 1024 * 1024;

/// Thin REST client for Firebase Storage.
///
/// The client is deliberately stateless — all per-operation state
/// (uploaded-bytes counter, cancel token) lives in the task wrappers so that
/// the underlying HTTP client can be shared by every plugin via
/// [TizenHttpClient].
@internal
class StorageRestClient {
  /// Creates a client rooted at [bucket] and authenticating through
  /// [tokenProvider] (typically [TizenAuthContext.instance.getIdToken]).
  StorageRestClient({
    required this.bucket,
    required this.appName,
    this.host = 'firebasestorage.googleapis.com',
  });

  /// Firebase Storage bucket name (no `gs://` prefix).
  final String bucket;

  /// Firebase app identifier for auth token lookup.
  final String appName;

  /// API host; override in tests or for emulator (not currently supported).
  final String host;

  Uri _objectUri(String path, {Map<String, String>? query}) {
    final String encoded = Uri.encodeComponent(path);
    return Uri.https(host, '/v0/b/$bucket/o/$encoded', query);
  }

  Uri _uploadUri(String path, {required String uploadType}) {
    return Uri.https(host, '/v0/b/$bucket/o', <String, String>{
      'uploadType': uploadType,
      'name': path,
    });
  }

  Uri _listUri({
    String? prefix,
    String? pageToken,
    int? maxResults,
  }) {
    return Uri.https(host, '/v0/b/$bucket/o', <String, String>{
      if (prefix != null) 'prefix': prefix,
      'delimiter': '/',
      if (pageToken != null) 'pageToken': pageToken,
      if (maxResults != null) 'maxResults': maxResults.toString(),
    });
  }

  Future<Map<String, String>> _authHeaders({
    Map<String, String>? extra,
    bool forceRefresh = false,
  }) async {
    final String? token = await TizenAuthContext.instance.getIdToken(
      appName,
      forceRefresh: forceRefresh,
    );
    return <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

  /// Retrieves object metadata.
  Future<Map<String, Object?>> getMetadata(String path) async {
    try {
      return await TizenHttpClient.instance.sendJson(
        method: 'GET',
        url: _objectUri(path),
        headers: await _authHeaders(),
      );
    } on TizenFirebaseHttpException catch (e) {
      throw StorageErrorMapper.fromHttpException(e);
    }
  }

  /// Updates server-writable metadata fields.
  Future<Map<String, Object?>> updateMetadata(
    String path,
    Map<String, Object?> metadata,
  ) async {
    try {
      return await TizenHttpClient.instance.sendJson(
        method: 'PATCH',
        url: _objectUri(path),
        headers: await _authHeaders(),
        body: metadata,
      );
    } on TizenFirebaseHttpException catch (e) {
      throw StorageErrorMapper.fromHttpException(e);
    }
  }

  /// Deletes an object.
  Future<void> deleteObject(String path) async {
    try {
      await TizenHttpClient.instance.sendRaw(
        method: 'DELETE',
        url: _objectUri(path),
        headers: await _authHeaders(),
      );
    } on TizenFirebaseHttpException catch (e) {
      throw StorageErrorMapper.fromHttpException(e);
    }
  }

  /// Lists objects matching [prefix].
  Future<Map<String, Object?>> list({
    String? prefix,
    String? pageToken,
    int? maxResults,
  }) async {
    try {
      return await TizenHttpClient.instance.sendJson(
        method: 'GET',
        url: _listUri(
          prefix: prefix,
          pageToken: pageToken,
          maxResults: maxResults,
        ),
        headers: await _authHeaders(),
      );
    } on TizenFirebaseHttpException catch (e) {
      throw StorageErrorMapper.fromHttpException(e);
    }
  }

  /// Returns a signed download URL for [path].
  Future<String> getDownloadUrl(String path) async {
    final Map<String, Object?> metadata = await getMetadata(path);
    final String? tokens = metadata['downloadTokens'] as String?;
    if (tokens == null || tokens.isEmpty) {
      throw StorageErrorMapper.map(
        404,
        message: 'Object "$path" has no download tokens.',
      );
    }
    final String firstToken = tokens.split(',').first;
    return _objectUri(path, query: <String, String>{
      'alt': 'media',
      'token': firstToken,
    }).toString();
  }

  /// Streams the object body to [sink] up to [maxSize] bytes.
  ///
  /// Aborts the stream (and throws) the moment the received body exceeds
  /// [maxSize]; callers should close [sink] in the `finally` block.
  Future<int> download(
    String path,
    StreamSink<List<int>> sink, {
    int? maxSize,
  }) async {
    final Map<String, Object?> metadata = await getMetadata(path);
    final String? tokens = metadata['downloadTokens'] as String?;
    final String? token = tokens?.split(',').firstOrNull;
    final Uri url = _objectUri(path, query: <String, String>{
      'alt': 'media',
      if (token != null) 'token': token,
    });
    final http.StreamedResponse response = await TizenHttpClient.instance
        .sendStreamed(method: 'GET', url: url, headers: await _authHeaders());
    if (response.statusCode >= 300) {
      final String body = await response.stream.bytesToString();
      throw StorageErrorMapper.map(
        response.statusCode,
        message: body,
      );
    }
    int received = 0;
    await for (final List<int> chunk in response.stream) {
      if (maxSize != null && received + chunk.length > maxSize) {
        throw StorageErrorMapper.map(
          413,
          message: 'Downloaded body exceeded maxSize=$maxSize bytes.',
        );
      }
      received += chunk.length;
      sink.add(chunk);
    }
    return received;
  }

  /// Performs a multipart upload suitable for payloads ≤
  /// [kResumableUploadThresholdBytes].
  Future<Map<String, Object?>> uploadMultipart({
    required String path,
    required List<int> data,
    Map<String, Object?>? metadata,
  }) async {
    // Unpredictable boundary: 24 random bytes hex-encoded. Picking a
    // boundary based on DateTime would allow adversarial callers to
    // fabricate a matching byte sequence inside their payload.
    final String boundary = _generateBoundary();

    // metadata['contentType'] is metadata-side truth; do NOT also
    // duplicate it on the body part header (Firebase rejects the
    // conflict).
    final Map<String, Object?> meta = <String, Object?>{
      'name': path,
      if (metadata != null) ...metadata,
    };
    final String? bodyContentType = metadata?['contentType'] as String?;
    final List<int> body = <int>[
      ...utf8.encode('--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '${jsonEncode(meta)}\r\n'
          '--$boundary\r\n'
          'Content-Type: ${bodyContentType ?? 'application/octet-stream'}\r\n\r\n'),
      ...data,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ];

    try {
      // Must go through sendRaw: sendJson would overwrite the
      // multipart Content-Type header and jsonEncode the bytes.
      final http.Response response =
          await TizenHttpClient.instance.sendRaw(
        method: 'POST',
        url: _uploadUri(path, uploadType: 'multipart'),
        headers: await _authHeaders(
          extra: <String, String>{
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
        ),
        body: body,
      );
      if (response.body.isEmpty) {
        return <String, Object?>{};
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      throw StorageErrorMapper.map(
        response.statusCode,
        message: 'Unexpected non-JSON response to multipart upload.',
      );
    } on TizenFirebaseHttpException catch (e) {
      throw StorageErrorMapper.fromHttpException(e);
    }
  }

  String _generateBoundary() {
    final Random rand = Random.secure();
    final List<int> bytes =
        List<int>.generate(24, (_) => rand.nextInt(256));
    return 'tizen-${bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Starts a resumable upload session and returns the session URI to `PUT`
  /// chunks against.
  Future<Uri> startResumable({
    required String path,
    required int totalBytes,
    required String contentType,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final http.Response response = await TizenHttpClient.instance.sendRaw(
        method: 'POST',
        url: _uploadUri(path, uploadType: 'resumable'),
        headers: await _authHeaders(
          extra: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'X-Goog-Upload-Protocol': 'resumable',
            'X-Goog-Upload-Command': 'start',
            'X-Goog-Upload-Header-Content-Length': '$totalBytes',
            'X-Goog-Upload-Header-Content-Type': contentType,
          },
        ),
        body: jsonEncode(<String, Object?>{
          'name': path,
          if (metadata != null) ...metadata,
        }),
      );
      final String? sessionUri =
          response.headers['x-goog-upload-url'] ?? response.headers['location'];
      if (sessionUri == null) {
        throw StorageErrorMapper.map(
          500,
          message: 'Server did not return a resumable session URI.',
        );
      }
      return Uri.parse(sessionUri);
    } on TizenFirebaseHttpException catch (e) {
      throw StorageErrorMapper.fromHttpException(e);
    }
  }

  /// Uploads [chunk] of the resumable session, returning the server's final
  /// metadata when the transfer is complete (status 200/201), or `null`
  /// while more chunks are still needed.
  ///
  /// GCS returns HTTP 308 "Resume Incomplete" after a non-final chunk; that
  /// is whitelisted via [TizenHttpClient.sendRaw.allowStatuses] so the
  /// client does not treat it as an error.
  Future<Map<String, Object?>?> uploadChunk({
    required Uri sessionUri,
    required List<int> chunk,
    required int byteOffset,
    required int totalBytes,
    required bool isFinal,
  }) async {
    try {
      final http.Response response = await TizenHttpClient.instance.sendRaw(
        method: 'PUT',
        url: sessionUri,
        headers: <String, String>{
          'X-Goog-Upload-Command':
              isFinal ? 'upload, finalize' : 'upload',
          'X-Goog-Upload-Offset': '$byteOffset',
        },
        body: chunk,
        allowStatuses: const <int>{308},
      );
      final String? uploadStatus =
          response.headers['x-goog-upload-status']?.toLowerCase();
      final bool completed = response.statusCode == 200 ||
          response.statusCode == 201 ||
          uploadStatus == 'final';
      if (completed && response.body.isNotEmpty) {
        final Object? decoded = jsonDecode(response.body);
        if (decoded is Map<String, Object?>) {
          return decoded;
        }
      }
      return null;
    } on TizenFirebaseHttpException catch (e) {
      throw StorageErrorMapper.fromHttpException(e);
    }
  }
}

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
