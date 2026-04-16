class FirebaseBackendException implements Exception {
  FirebaseBackendException(this.message, {this.details});

  final String message;
  final Object? details;

  @override
  String toString() {
    if (details == null) {
      return 'FirebaseBackendException($message)';
    }
    return 'FirebaseBackendException($message, details: $details)';
  }
}
