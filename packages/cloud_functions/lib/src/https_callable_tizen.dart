// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';

import 'callable_rest_client.dart';
import 'functions_error_mapper.dart';

/// Tizen [HttpsCallablePlatform] delegate.
class HttpsCallableTizen extends HttpsCallablePlatform {
  /// Constructs a callable that dispatches to [client].
  HttpsCallableTizen(
    FirebaseFunctionsPlatform functions,
    String? origin,
    String? name,
    HttpsCallableOptions options,
    Uri? uri,
    this._client,
  ) : super(functions, origin, name, options, uri);

  final CallableRestClient _client;

  @override
  Future<Object?> call([Object? parameters]) async {
    final Uri target;
    if (uri != null) {
      target = uri!;
    } else if (name != null) {
      target = _client.gen1Uri(name!);
    } else {
      throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'HttpsCallable requires either a name or a uri.',
      );
    }

    try {
      return await _client.invoke(
        target,
        parameters: parameters,
        timeout: options.timeout,
      );
    } on TizenFirebaseHttpException catch (error) {
      throw FunctionsErrorMapper.map(
        statusCode: error.statusCode,
        payload: _safeParse(error.responseBody),
      );
    }
  }

  Map<String, Object?>? _safeParse(String body) {
    try {
      final dynamic decoded = _client.codec.decodeDynamic(body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
    } catch (_) {
      // Non-JSON body; surface a synthetic structure.
    }
    return <String, Object?>{
      'error': <String, Object?>{'message': body},
    };
  }
}
