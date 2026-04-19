// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:meta/meta.dart';

/// Thin REST client for the Firebase Installations API.
@internal
class InstallationsRestClient {
  /// Creates a client targeting [projectId] with the given [apiKey] and
  /// [appId].
  InstallationsRestClient({
    required this.apiKey,
    required this.projectId,
    required this.appId,
    this.host = 'firebaseinstallations.googleapis.com',
  });

  /// The Firebase web API key used as a query parameter.
  final String apiKey;

  /// Firebase project identifier.
  final String projectId;

  /// App identifier from `FirebaseOptions.appId`.
  final String appId;

  /// API host (overridable for tests).
  final String host;

  Uri _createUri() => Uri.https(
        host,
        '/v1/projects/$projectId/installations',
        <String, String>{'key': apiKey},
      );

  Uri _refreshUri(String fid) => Uri.https(
        host,
        '/v1/projects/$projectId/installations/$fid/authTokens:generate',
        <String, String>{'key': apiKey},
      );

  Uri _deleteUri(String fid) => Uri.https(
        host,
        '/v1/projects/$projectId/installations/$fid',
        <String, String>{'key': apiKey},
      );

  /// Registers the given [fid] with the Installations service and returns
  /// the initial auth token and expiration metadata.
  Future<InstallationsAuthToken> create(String fid) async {
    final Map<String, Object?> response = await TizenHttpClient.instance
        .sendJson(
      method: 'POST',
      url: _createUri(),
      headers: _headers(),
      body: <String, Object?>{
        'fid': fid,
        'appId': appId,
        'authVersion': 'FIS_v2',
        'sdkVersion': _sdkVersion,
      },
    );
    return InstallationsAuthToken.fromJson(
      response['authToken'] as Map<String, Object?>? ?? <String, Object?>{},
    );
  }

  /// Generates a fresh installation auth token for [fid].
  Future<InstallationsAuthToken> generate(String fid) async {
    final Map<String, Object?> response =
        await TizenHttpClient.instance.sendJson(
      method: 'POST',
      url: _refreshUri(fid),
      headers: _headers(),
      body: const <String, Object?>{
        'installation': <String, Object?>{
          'sdkVersion': _sdkVersion,
        }
      },
    );
    return InstallationsAuthToken.fromJson(response);
  }

  /// Deletes the installation identified by [fid] (idempotent).
  Future<void> delete(String fid) async {
    await TizenHttpClient.instance.sendRaw(
      method: 'DELETE',
      url: _deleteUri(fid),
      headers: _headers(),
    );
  }

  Map<String, String> _headers() => <String, String>{
        'x-goog-api-key': apiKey,
        // Mimic the iOS SDK user-agent so gating rules on the server do not
        // reject requests from an unrecognised client.
        'x-firebase-client': 'tizen:firebase_app_installations_tizen:0.1.0',
      };

  static const String _sdkVersion = 't:0.1.0';
}

/// Parsed Installations auth-token payload.
class InstallationsAuthToken {
  /// Creates a token with an explicit expiration timestamp.
  InstallationsAuthToken({
    required this.token,
    required this.expiresAt,
  });

  /// Parses the JSON `authToken` object returned by the Installations API.
  factory InstallationsAuthToken.fromJson(Map<String, Object?> json) {
    final String token = (json['token'] ?? '') as String;
    final String? expiresIn = json['expiresIn'] as String?;
    final Duration ttl = _parseDuration(expiresIn);
    return InstallationsAuthToken(
      token: token,
      expiresAt: DateTime.now().toUtc().add(ttl),
    );
  }

  /// JWT bearer token.
  final String token;

  /// Wall-clock expiration time in UTC.
  final DateTime expiresAt;

  /// Whether the token is safe to use right now (with a 5-minute margin).
  bool get isFresh {
    return DateTime.now()
        .toUtc()
        .isBefore(expiresAt.subtract(const Duration(minutes: 5)));
  }

  static Duration _parseDuration(String? value) {
    if (value == null || value.isEmpty) {
      return const Duration(hours: 1);
    }
    final RegExpMatch? match = RegExp(r'(\d+)s').firstMatch(value);
    if (match == null) {
      return const Duration(hours: 1);
    }
    return Duration(seconds: int.parse(match.group(1)!));
  }
}
