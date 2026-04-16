import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_tizen/firebase_auth_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers FirebaseAuthTizen as the platform instance', () {
    FirebaseAuthTizen.register();

    expect(FirebaseAuthPlatform.instance, isA<FirebaseAuthTizen>());
  });
}
