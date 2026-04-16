import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers FirebaseCore as the platform instance', () {
    FirebaseCore.register();

    expect(FirebasePlatform.instance, isA<FirebaseCore>());
  });
}
