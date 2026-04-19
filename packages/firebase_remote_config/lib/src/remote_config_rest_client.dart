// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// REST client for the (officially undocumented) client-side Remote Config
/// fetch endpoint used by every native SDK.
///
/// The endpoint path is stable — `firebase-js-sdk`, `firebase-ios-sdk`, and
/// `firebase-android-sdk` all point at
/// `firebaseremoteconfig.googleapis.com/v1/projects/{projectId}/namespaces/{ns}:fetch`.
/// Request bodies are JSON and identify the app/instance so Remote Config can
/// evaluate personalisation, and responses carry the entire parameter map plus
/// an `etag` used on the next request.
@internal
class RemoteConfigRestClient {
  /// Creates a client rooted at [projectId] with the supplied [apiKey] and
  /// [appId].
  RemoteConfigRestClient({
    required this.apiKey,
    required this.projectId,
    required this.appId,
    this.namespace = 'firebase',
    this.host = 'firebaseremoteconfig.googleapis.com',
  });

  /// Firebase Web API key.
  final String apiKey;

  /// Firebase project identifier.
  final String projectId;

  /// `FirebaseOptions.appId`.
  final String appId;

  /// Remote Config namespace (defaults to the standard `firebase`).
  final String namespace;

  /// API host; overridable for tests.
  final String host;

  Uri _fetchUri() {
    return Uri.https(
      host,
      '/v1/projects/$projectId/namespaces/$namespace:fetch',
      <String, String>{'key': apiKey},
    );
  }

  /// Performs a fetch, returning [RemoteConfigFetchResponse.notModified] when
  /// the server replies 304, or [RemoteConfigFetchResponse.updated] otherwise.
  Future<RemoteConfigFetchResponse> fetch({
    required String installationId,
    required String installationToken,
    String? etag,
    String languageCode = 'en',
  }) async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Goog-Api-Key': apiKey,
      if (etag != null) 'If-None-Match': etag,
    };
    final Map<String, Object?> body = <String, Object?>{
      'sdk_version': 't:0.1.0',
      'app_instance_id': installationId,
      'app_instance_id_token': installationToken,
      'app_id': appId,
      'language_code': languageCode,
    };
    try {
      final http.Response response = await TizenHttpClient.instance.sendRaw(
        method: 'POST',
        url: _fetchUri(),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 304) {
        return const RemoteConfigFetchResponse.notModified();
      }
      final Map<String, Object?> decoded =
          jsonDecode(response.body) as Map<String, Object?>;
      final Object? rawEntries = decoded['entries'];
      final Map<String, Object?> entries = rawEntries is Map<String, Object?>
          ? rawEntries
          : <String, Object?>{};
      final String? serverEtag = response.headers['etag'];
      return RemoteConfigFetchResponse.updated(
        entries: entries,
        etag: serverEtag,
      );
    } on TizenFirebaseHttpException catch (error) {
      if (error.statusCode == 304) {
        return const RemoteConfigFetchResponse.notModified();
      }
      rethrow;
    }
  }
}

/// Result of a Remote Config fetch.
class RemoteConfigFetchResponse {
  /// 304 Not Modified response — keep the prior payload in place.
  const RemoteConfigFetchResponse.notModified()
      : notModified = true,
        entries = const <String, Object?>{},
        etag = null;

  /// 200 OK response carrying fresh [entries] and a new [etag].
  const RemoteConfigFetchResponse.updated({
    required this.entries,
    required this.etag,
  }) : notModified = false;

  /// Whether the server indicated the cached payload is still current.
  final bool notModified;

  /// Raw parameter values (stringified) from the server.
  final Map<String, Object?> entries;

  /// ETag for the payload; pass back on the next fetch.
  final String? etag;
}
