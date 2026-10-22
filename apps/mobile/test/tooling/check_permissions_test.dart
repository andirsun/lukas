import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// scripts/check-permissions.sh, fed a recorded `aapt2 dump permissions` output instead of a built
/// APK (CI runs it for real on the release APK).
Future<ProcessResult> _check(String dump) async {
  final dir = await Directory.systemTemp.createTemp('check-permissions');
  addTearDown(() => dir.delete(recursive: true));
  final file = File('${dir.path}/permissions.txt')..writeAsStringSync(dump);
  return Process.run('bash', ['scripts/check-permissions.sh', '--dump', file.path]);
}

const _receiver = '''
permission: com.andersonlaverde.lukitas.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
uses-permission: name='com.andersonlaverde.lukitas.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
''';

void main() {
  test('release permissions: INTERNET and the AndroidX receiver permission pass', () async {
    final result = await _check(
      'package: com.andersonlaverde.lukitas\n'
      "uses-permission: name='android.permission.INTERNET'\n$_receiver",
    );
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('release permissions: no INTERNET fails (the app could not reach its server)', () async {
    final result = await _check('package: com.andersonlaverde.lukitas\n$_receiver');
    expect(result.exitCode, 1);
    expect(result.stdout, contains('android.permission.INTERNET'));
  });

  test('release permissions: an unexpected permission fails with its name', () async {
    final result = await _check(
      'package: com.andersonlaverde.lukitas\n'
      "uses-permission: name='android.permission.INTERNET'\n"
      "uses-permission: name='com.google.android.gms.permission.AD_ID'\n$_receiver",
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.android.gms.permission.AD_ID'));
  });

  test('release permissions: a missing APK is an error, not a pass', () async {
    final result = await Process.run('bash', [
      'scripts/check-permissions.sh',
      '--apk',
      '/nonexistent/app-release.apk',
    ]);
    expect(result.exitCode, 2);
  });
}
