import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('backup is off: the Keystore-bound session token cannot be restored on another device', () {
    expect(manifest, contains('android:allowBackup="false"'));
  });
}
