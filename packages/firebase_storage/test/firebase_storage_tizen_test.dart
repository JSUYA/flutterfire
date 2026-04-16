import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_storage_tizen/firebase_storage_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers FirebaseStorageTizen as the platform instance', () {
    FirebaseStorageTizen.register();

    expect(FirebaseStoragePlatform.instance, isA<FirebaseStorageTizen>());
  });
}
