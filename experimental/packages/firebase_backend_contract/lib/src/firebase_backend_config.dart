class FirebaseBackendConfig {
  const FirebaseBackendConfig({
    required this.apiKey,
    required this.projectId,
    this.authBaseUrl = 'https://identitytoolkit.googleapis.com/v1',
    this.functionsBaseUrl,
  });

  final String apiKey;
  final String projectId;
  final String authBaseUrl;
  final String? functionsBaseUrl;

  String buildSignInUrl() {
    return '$authBaseUrl/accounts:signInWithPassword?key=$apiKey';
  }

  String buildCallableUrl(
    String name, {
    String region = 'us-central1',
  }) {
    final String? configuredFunctionsBaseUrl = functionsBaseUrl;
    if (configuredFunctionsBaseUrl != null) {
      return '$configuredFunctionsBaseUrl/$projectId/$region/$name';
    }

    return 'https://$region-$projectId.cloudfunctions.net/$name';
  }

  Map<String, Object?> toBridgeMap() {
    return <String, Object?>{
      'apiKey': apiKey,
      'projectId': projectId,
      'authBaseUrl': authBaseUrl,
      'functionsBaseUrl': functionsBaseUrl,
    };
  }
}
