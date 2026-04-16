// ignore_for_file: one_member_abstracts

import 'dart:convert';

abstract interface class FirebaseWebBridgeTransport {
  Future<Object?> invoke(
    String command,
    Map<String, Object?> arguments,
  );
}

abstract interface class JavaScriptEvaluator {
  Future<String?> evaluate(String script);
}

class EvaluatingWebViewTransport implements FirebaseWebBridgeTransport {
  EvaluatingWebViewTransport(this._evaluator);

  final JavaScriptEvaluator _evaluator;

  @override
  Future<Object?> invoke(
    String command,
    Map<String, Object?> arguments,
  ) async {
    final String script = '''
(async function() {
  const result = await globalThis.firebaseTizenBridge.execute(
    ${jsonEncode(command)},
    ${jsonEncode(arguments)}
  );
  return JSON.stringify(result);
})()
''';

    final String? rawResult = await _evaluator.evaluate(script);
    if (rawResult == null) {
      throw StateError('The WebView evaluator returned null.');
    }

    final Object? normalized = _normalizeResult(rawResult);
    if (normalized is String) {
      return jsonDecode(normalized);
    }
    return normalized;
  }

  Object? _normalizeResult(String rawResult) {
    final String trimmed = rawResult.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(trimmed);
    } on FormatException {
      return trimmed;
    }
  }
}
