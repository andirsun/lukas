import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// scripts/check-no-google.sh, fed recorded dependency listings instead of running Gradle and pub
/// (CI runs it for real on the resolved dependencies).
Future<ProcessResult> _check({required String gradle, required String pub}) async {
  final dir = await Directory.systemTemp.createTemp('check-no-google');
  addTearDown(() => dir.delete(recursive: true));
  final gradleFile = File('${dir.path}/gradle.txt')..writeAsStringSync(gradle);
  final pubFile = File('${dir.path}/pub.txt')..writeAsStringSync(pub);
  return Process.run('bash', [
    'scripts/check-no-google.sh',
    '--gradle-deps',
    gradleFile.path,
    '--pub-deps',
    pubFile.path,
  ]);
}

const _cleanGradle = '''
releaseRuntimeClasspath - Runtime classpath of '/release'.
+--- io.flutter:flutter_embedding_release:1.0.0-deb287481e
|    +--- androidx.lifecycle:lifecycle-common:2.7.0
|    +--- androidx.window:window-java:1.2.0
|    \\--- com.getkeepsafe.relinker:relinker:1.4.5
\\--- org.jetbrains.kotlin:kotlin-stdlib:2.4.0
''';

const _cleanPub = '''
Dart SDK 3.13.5
Flutter SDK 3.47.7
lukitas 1.0.0+1

dependencies:
- dio 5.11.1 [async collection http_parser meta mime path dio_web_adapter]
- flutter_riverpod 3.4.3 [collection flutter meta riverpod state_notifier]
- go_router 18.0.2 [collection flutter flutter_web_plugins logging meta]
''';

void main() {
  test('no Google dependency: clean listings pass', () async {
    final result = await _check(gradle: _cleanGradle, pub: _cleanPub);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('no Google dependency: Play Services in Gradle fails with its name', () async {
    final result = await _check(
      gradle:
          '$_cleanGradle+--- com.google.android.gms:play-services-base:18.5.0\n'
          '+--- com.google.android.play:integrity:1.4.0\n',
      pub: _cleanPub,
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.android.gms:play-services-base'));
    expect(result.stdout, contains('com.google.android.play:integrity'));
  });

  test('no Google dependency: Firebase and ML Kit fail with their names', () async {
    final result = await _check(
      gradle: '$_cleanGradle+--- com.google.mlkit:text-recognition:16.0.1\n',
      pub: '$_cleanPub- firebase_core 4.2.0 [firebase_core_platform_interface flutter meta]\n',
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.mlkit:text-recognition'));
    expect(result.stdout, contains('firebase_core'));
  });

  test('no Google dependency: a missing listing is an error, not a pass', () async {
    final result = await Process.run('bash', [
      'scripts/check-no-google.sh',
      '--gradle-deps',
      '/nonexistent/gradle.txt',
      '--pub-deps',
      '/nonexistent/pub.txt',
    ]);
    expect(result.exitCode, isNot(0));
  });
}
