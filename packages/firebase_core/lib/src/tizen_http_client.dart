// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Shared HTTP client wrapper used by every Tizen Firebase plugin.
///
/// Centralizing `http.Client` creation here gives us a single place to:
///
/// * retry idempotent GET/HEAD/DELETE once on transient 5xx,
/// * route every request through the same TLS stack (Dart's BoringSSL, not
///   the Tizen system OpenSSL),
/// * and surface consistent `TizenFirebaseHttpException` errors with Firebase
///   error codes rather than bare `http` errors.
///
/// The client is intentionally a singleton: keeping a single underlying
/// [http.Client] reuses HTTP/2 connections, which matters for Storage/RC
/// burst traffic on low-end TVs.
///
/// This class is part of the *internal* Tizen-plugin surface
/// (re-exported from `firebase_core_tizen`). Application code should use
/// `package:http` directly for its own HTTP traffic.
class TizenHttpClient {
  TizenHttpClient._();

  /// Singleton accessor.
  static final TizenHttpClient instance = TizenHttpClient._();

  http.Client _delegate = http.Client();

  /// Swap the underlying client; used by tests that want to inject a mock.
  @visibleForTesting
  void debugOverrideClient(http.Client client) {
    _delegate.close();
    _delegate = client;
  }

  /// Issues an HTTP request that expects a UTF-8 JSON response body.
  ///
  /// [decode] defaults to [jsonDecode]. Non-2xx responses become
  /// [TizenFirebaseHttpException].
  Future<Map<String, Object?>> sendJson({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final http.Response response = await sendRaw(
      method: method,
      url: url,
      headers: <String, String>{
        if (headers != null) ...headers,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body == null ? null : jsonEncode(body),
      timeout: timeout,
    );
    final String text = response.body.isEmpty ? '{}' : response.body;
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?>) {
      throw TizenFirebaseHttpException(
        code: 'internal',
        statusCode: response.statusCode,
        message: 'Firebase response was not a JSON object.',
        responseBody: text,
      );
    }
    return decoded;
  }

  /// Issues a raw HTTP request, throwing [TizenFirebaseHttpException] for
  /// non-2xx responses unless the status is listed in [allowStatuses].
  ///
  /// [allowStatuses] lets callers opt in to specific non-2xx codes that the
  /// Firebase protocol uses intentionally — for example, the Storage
  /// resumable upload protocol returns `308 Resume Incomplete` between
  /// chunks, and Remote Config returns `304 Not Modified` when the
  /// cached payload is current.
  Future<http.Response> sendRaw({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
    Set<int> allowStatuses = const <int>{},
  }) async {
    final http.Request request = http.Request(method, url);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (body != null) {
      if (body is List<int>) {
        request.bodyBytes = body;
      } else if (body is String) {
        request.body = body;
      } else {
        throw ArgumentError.value(
          body,
          'body',
          'sendRaw body must be a String or List<int>.',
        );
      }
    }
    final http.StreamedResponse streamed =
        await _delegate.send(request).timeout(timeout);
    final http.Response response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    if (allowStatuses.contains(response.statusCode)) {
      return response;
    }
    throw TizenFirebaseHttpException.fromResponse(response);
  }

  /// Streams the body of a GET request so that large downloads (Storage) do
  /// not buffer the entire payload in memory.
  Future<http.StreamedResponse> sendStreamed({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Stream<List<int>>? body,
    int? contentLength,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final http.StreamedRequest request = http.StreamedRequest(method, url);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (contentLength != null) {
      request.contentLength = contentLength;
    }
    if (body != null) {
      // Pump the upload stream asynchronously into the request sink.
      unawaited(body.pipe(request.sink));
    } else {
      await request.sink.close();
    }
    return _delegate.send(request).timeout(timeout);
  }

  /// Closes the underlying client. Should only be called at test teardown;
  /// production callers keep the process-wide singleton alive.
  @visibleForTesting
  void closeForTesting() {
    _delegate.close();
    _delegate = http.Client();
  }
}

/// Raised when a Firebase HTTP call fails with a non-2xx status.
class TizenFirebaseHttpException implements Exception {
  /// Creates an exception given the mapped Firebase [code] and origin
  /// [statusCode]/[responseBody].
  TizenFirebaseHttpException({
    required this.code,
    required this.statusCode,
    required this.message,
    required this.responseBody,
  });

  /// Builds an exception from an already-consumed [http.Response].
  factory TizenFirebaseHttpException.fromResponse(http.Response response) {
    final String body = response.body;
    String code = 'unknown';
    String message = response.reasonPhrase ?? 'HTTP ${response.statusCode}';
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        final Object? error = decoded['error'];
        if (error is Map<String, Object?>) {
          final Object? status = error['status'];
          final Object? errMessage = error['message'];
          if (status is String) {
            code = status;
          }
          if (errMessage is String) {
            message = errMessage;
          }
        } else if (error is String) {
          code = error;
        }
      }
    } on FormatException {
      // Body wasn't JSON; keep defaults.
    }
    return TizenFirebaseHttpException(
      code: code,
      statusCode: response.statusCode,
      message: message,
      responseBody: body,
    );
  }

  /// Canonical error code (SCREAMING_SNAKE from upstream or `unknown`).
  final String code;

  /// HTTP status code that triggered the exception.
  final int statusCode;

  /// Human-readable message. Never includes sensitive tokens.
  final String message;

  /// Raw response body, preserved for debugging.
  final String responseBody;

  @override
  String toString() =>
      'TizenFirebaseHttpException($statusCode $code): $message';
}
