import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart'
    show FirebaseTizenRuntime;
import 'package:firebase_dart/auth.dart' as firebase_auth_dart;
import 'package:firebase_dart/firebase_dart.dart' as firebase_dart;
import 'package:http/http.dart' as http;

/// Tizen implementation of [FirebaseFunctionsPlatform].
class FirebaseFunctionsTizen extends FirebaseFunctionsPlatform {
  /// Creates a new instance of the Tizen functions platform.
  FirebaseFunctionsTizen({FirebaseApp? app, required String region})
      : super(app, region);

  /// Registers this implementation as the default functions platform.
  static void register() {
    FirebaseFunctionsPlatform.instance = FirebaseFunctionsTizen(
      region: 'us-central1',
    );
  }

  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) {
    return FirebaseFunctionsTizen(app: app, region: region);
  }

  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) {
    return _FirebaseHttpsCallableTizen(
      functions: this,
      origin: origin,
      name: name,
      options: options,
      uri: null,
    );
  }

  @override
  HttpsCallablePlatform httpsCallableWithUri(
    String? origin,
    Uri uri,
    HttpsCallableOptions options,
  ) {
    return _FirebaseHttpsCallableTizen(
      functions: this,
      origin: origin,
      name: null,
      options: options,
      uri: uri,
    );
  }
}

class _FirebaseHttpsCallableTizen extends HttpsCallablePlatform {
  _FirebaseHttpsCallableTizen({
    required FirebaseFunctionsPlatform functions,
    required String? origin,
    required String? name,
    required HttpsCallableOptions options,
    required Uri? uri,
  }) : super(functions, origin, name, options, uri);

  @override
  Future<dynamic> call([dynamic parameters]) async {
    await FirebaseTizenRuntime.ensureInitialized();

    final Uri endpoint = _resolveEndpoint();
    final Map<String, Object?> payload = <String, Object?>{
      'data': _encodeValue(parameters),
    };

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final FirebaseApp firebaseApp = functions.app ?? Firebase.app();
    final firebase_dart.FirebaseApp dartApp =
        FirebaseTizenRuntime.dartAppForPublicApp(firebaseApp);
    final firebase_auth_dart.FirebaseAuth auth =
        firebase_auth_dart.FirebaseAuth.instanceFor(app: dartApp);
    final firebase_auth_dart.User? user = auth.currentUser;
    if (user != null) {
      headers['Authorization'] = 'Bearer ${await user.getIdToken()}';
    }

    try {
      final http.Response response = await http
          .post(endpoint, headers: headers, body: jsonEncode(payload))
          .timeout(options.timeout);

      return _decodeResponse(response);
    } on TimeoutException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FirebaseFunctionsException(
          code: 'deadline-exceeded',
          message: error.message ?? 'The callable request timed out.',
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    } on FirebaseFunctionsException {
      rethrow;
    } on http.ClientException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FirebaseFunctionsException(
          code: 'unavailable',
          message: error.message,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Stream<dynamic> stream(Object? parameters) {
    throw UnimplementedError(
      'Streaming callable responses are not supported on Tizen yet.',
    );
  }

  Uri _resolveEndpoint() {
    if (uri != null) {
      return uri!;
    }

    final FirebaseApp resolvedApp = functions.app ?? Firebase.app();
    final String projectId = resolvedApp.options.projectId;
    final String functionName = name!;

    if (origin != null) {
      return Uri.parse('$origin/$projectId/${functions.region}/$functionName');
    }

    return Uri.https(
      '${functions.region}-$projectId.cloudfunctions.net',
      functionName,
    );
  }

  dynamic _decodeResponse(http.Response response) {
    final Object? decodedBody =
        response.body.isEmpty ? null : jsonDecode(response.body) as Object?;

    if (decodedBody is! Map) {
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'Callable response was not a valid JSON object.',
      );
    }

    final Map<String, Object?> body = decodedBody.map<String, Object?>(
      (dynamic key, dynamic value) =>
          MapEntry<String, Object?>(key.toString(), value),
    );

    final Map<String, Object?>? error = switch (body['error']) {
      final Map value => value.map<String, Object?>(
          (dynamic key, dynamic nestedValue) =>
              MapEntry<String, Object?>(key.toString(), nestedValue),
        ),
      _ => null,
    };
    if (error != null) {
      throw FirebaseFunctionsException(
        code: _mapStatus(error['status'] as String?),
        message: (error['message'] as String?) ?? 'Callable request failed.',
        details: _decodeValue(error['details']),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'Callable request failed with HTTP ${response.statusCode}.',
      );
    }

    if (body.containsKey('result')) {
      return _decodeValue(body['result']);
    }
    if (body.containsKey('data')) {
      return _decodeValue(body['data']);
    }
    if (body.containsKey('response')) {
      return _decodeValue(body['response']);
    }

    throw FirebaseFunctionsException(
      code: 'internal',
      message: 'Callable response was missing a result payload.',
    );
  }

  Object? _encodeValue(Object? value) {
    if (value == null || value is bool || value is double || value is String) {
      return value;
    }

    if (value is int) {
      if (value > 2147483647 || value < -2147483648) {
        return <String, Object?>{
          '@type': 'type.googleapis.com/google.protobuf.Int64Value',
          'value': value.toString(),
        };
      }
      return value;
    }

    if (value is Uint8List) {
      return value.toList();
    }

    if (value is Int32List) {
      return value.toList();
    }

    if (value is Int64List) {
      return value.toList();
    }

    if (value is Float32List) {
      return value.toList();
    }

    if (value is Float64List) {
      return value.toList();
    }

    if (value is List) {
      return value.map<Object?>(_encodeValue).toList(growable: false);
    }

    if (value is Map) {
      return value.map<String, Object?>(
        (dynamic key, dynamic nestedValue) => MapEntry<String, Object?>(
          key.toString(),
          _encodeValue(nestedValue),
        ),
      );
    }

    return value;
  }

  dynamic _decodeValue(Object? value) {
    if (value is List) {
      return value.map<dynamic>(_decodeValue).toList(growable: false);
    }

    if (value is Map) {
      final Map<String, Object?> normalized = value.map<String, Object?>(
        (dynamic key, dynamic nestedValue) =>
            MapEntry<String, Object?>(key.toString(), nestedValue),
      );
      final String? type = normalized['@type'] as String?;
      if (type == 'type.googleapis.com/google.protobuf.Int64Value' ||
          type == 'type.googleapis.com/google.protobuf.UInt64Value') {
        return int.tryParse(normalized['value']?.toString() ?? '');
      }

      return normalized.map<String, dynamic>(
        (String key, Object? nestedValue) =>
            MapEntry<String, dynamic>(key, _decodeValue(nestedValue)),
      );
    }

    return value;
  }

  String _mapStatus(String? status) {
    switch (status) {
      case 'CANCELLED':
        return 'cancelled';
      case 'UNKNOWN':
        return 'unknown';
      case 'INVALID_ARGUMENT':
        return 'invalid-argument';
      case 'DEADLINE_EXCEEDED':
        return 'deadline-exceeded';
      case 'NOT_FOUND':
        return 'not-found';
      case 'ALREADY_EXISTS':
        return 'already-exists';
      case 'PERMISSION_DENIED':
        return 'permission-denied';
      case 'RESOURCE_EXHAUSTED':
        return 'resource-exhausted';
      case 'FAILED_PRECONDITION':
        return 'failed-precondition';
      case 'ABORTED':
        return 'aborted';
      case 'OUT_OF_RANGE':
        return 'out-of-range';
      case 'UNIMPLEMENTED':
        return 'unimplemented';
      case 'INTERNAL':
        return 'internal';
      case 'UNAVAILABLE':
        return 'unavailable';
      case 'DATA_LOSS':
        return 'data-loss';
      case 'UNAUTHENTICATED':
        return 'unauthenticated';
      default:
        return 'internal';
    }
  }
}
