class FirebaseUserSession {
  const FirebaseUserSession({
    required this.idToken,
    required this.refreshToken,
    required this.localId,
    this.email,
  });

  factory FirebaseUserSession.fromJson(Map<String, Object?> json) {
    return FirebaseUserSession(
      idToken: json['idToken']! as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
      localId: (json['localId'] ?? '') as String,
      email: json['email'] as String?,
    );
  }

  final String idToken;
  final String refreshToken;
  final String localId;
  final String? email;
}
