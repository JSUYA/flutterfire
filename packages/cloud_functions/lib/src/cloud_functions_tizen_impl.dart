// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';

import 'callable_rest_client.dart';
import 'https_callable_tizen.dart';

/// Tizen implementation of [FirebaseFunctionsPlatform].
class CloudFunctionsTizen extends FirebaseFunctionsPlatform {
  /// Private constructor used by [register] and [delegateFor].
  CloudFunctionsTizen._({
    FirebaseApp? app,
    String region = 'us-central1',
  })  : _client = CallableRestClient(
          appName: app?.name ?? defaultFirebaseAppName,
          region: region,
          projectId: app?.options.projectId ?? '',
        ),
        // FirebaseFunctionsPlatform(this.app, this.region) takes positional
        // args; passing them as named fails to compile.
        super(app, region);

  /// Entry point registered via
  /// `dartPluginClass: CloudFunctionsTizen` in `pubspec.yaml`.
  static void register() {
    FirebaseFunctionsPlatform.instance = CloudFunctionsTizen._();
  }

  final CallableRestClient _client;

  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) {
    return CloudFunctionsTizen._(app: app, region: region);
  }

  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) {
    if (origin != null) {
      throw UnimplementedError(
        'useFunctionsEmulator/origin override is not supported by '
        'cloud_functions_tizen. Reason: emulator loopback TLS is not trusted '
        'by Tizen TV devices.',
      );
    }
    return HttpsCallableTizen(this, origin, name, options, null, _client);
  }

  @override
  HttpsCallablePlatform httpsCallableWithUri(
    String? origin,
    Uri uri,
    HttpsCallableOptions options,
  ) {
    if (origin != null) {
      throw UnimplementedError(
        'useFunctionsEmulator is not supported on Tizen.',
      );
    }
    return HttpsCallableTizen(this, null, null, options, uri, _client);
  }
}
