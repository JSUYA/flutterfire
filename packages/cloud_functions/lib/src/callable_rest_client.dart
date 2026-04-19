// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:meta/meta.dart';

import 'functions_error_mapper.dart';

/// HTTPS callable REST client.
///
/// Handles the Firebase callable wire format:
///   request:  { "data": <payload> }
///   response: { "data": <payload> } | { "error": { "status", "message", "details" } }
///
/// ID tokens are read from [TizenAuthContext] so every callable uses the
/// shared singleflight refresh loop.
@internal
class CallableRestClient {
  /// Creates a client for [appName] rooted at [region] within [projectId].
  CallableRestClient({
    required this.appName,
    required this.region,
    required this.projectId,
  });

  /// Firebase app used to look up auth tokens.
  final String appName;

  /// Cloud Functions region (e.g. `us-central1`).
  final String region;

  /// Firebase project identifier.
  final String projectId;

  /// Exposed so callers can re-parse error payloads without bringing
  /// dart:convert into scope themselves.
  final CallableCodec codec = const CallableCodec();

  /// Builds the gen1 function URL by convention:
  /// `https://<region>-<project>.cloudfunctions.net/<name>`.
  Uri gen1Uri(String name) {
    return Uri.https('$region-$projectId.cloudfunctions.net', '/$name');
  }

  /// Performs the callable POST, returning the decoded `data` payload.
  Future<Object?> invoke(
    Uri target, {
    Object? parameters,
    Duration timeout = const Duration(seconds: 70),
  }) async {
    final String? token = await TizenAuthContext.instance.getIdToken(appName);
    final Map<String, Object?> body = <String, Object?>{
      'data': codec.encode(parameters),
    };
    final Map<String, Object?> response =
        await TizenHttpClient.instance.sendJson(
      method: 'POST',
      url: target,
      headers: <String, String>{
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
      timeout: timeout,
    );
    if (response.containsKey('error')) {
      throw FunctionsErrorMapper.map(
        statusCode: 400,
        payload: response,
      );
    }
    return codec.decode(response['data'] ?? response['result']);
  }
}

/// Callable wire codec handling Firebase's Long wrapping convention.
class CallableCodec {
  /// Creates a const instance.
  const CallableCodec();

  /// Encodes Dart values into the JSON envelope expected by the server.
  Object? encode(Object? value) {
    if (value is int && (value > _safeMax || value < -_safeMax)) {
      return <String, Object?>{
        '@type': 'type.googleapis.com/google.protobuf.Int64Value',
        'value': value.toString(),
      };
    }
    if (value is List<Object?>) {
      return value.map(encode).toList();
    }
    if (value is Map) {
      return value.map((Object? key, Object? v) =>
          MapEntry<Object?, Object?>(key, encode(v)));
    }
    return value;
  }

  /// Decodes a server payload into Dart values, unwrapping the Int64 tag.
  Object? decode(Object? value) {
    if (value is Map<String, Object?>) {
      final Object? type = value['@type'];
      final Object? payload = value['value'];
      if (type == 'type.googleapis.com/google.protobuf.Int64Value' &&
          payload is String) {
        return int.parse(payload);
      }
      return value.map((String key, Object? v) =>
          MapEntry<String, Object?>(key, decode(v)));
    }
    if (value is List) {
      return value.map(decode).toList();
    }
    return value;
  }

  /// Helper: parse a JSON text body and return raw (pre-decode) dynamic.
  dynamic decodeDynamic(String text) {
    if (text.isEmpty) {
      return null;
    }
    return jsonDecode(text);
  }

  static const int _safeMax = 9007199254740992; // 2^53
}
