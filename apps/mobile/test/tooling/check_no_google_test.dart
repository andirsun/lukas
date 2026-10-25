import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// scripts/check-no-google.sh, fed recorded dependency listings and a fixture android/ directory
/// instead of running Gradle and pub on the app (CI runs it for real, and
/// scripts/test-no-google-probes.sh runs it on a copy of the app with banned dependencies added).
Future<ProcessResult> _check({
  String? gradle,
  String pub = _cleanPub,
  String buildFile = _cleanBuildFile,
}) async {
  final dir = await Directory.systemTemp.createTemp('check-no-google');
  addTearDown(() => dir.delete(recursive: true));
  final gradleFile = File('${dir.path}/gradle.txt')..writeAsStringSync(gradle ?? _cleanGradle);
  final pubFile = File('${dir.path}/pub.txt')..writeAsStringSync(pub);
  final android = Directory('${dir.path}/android/app')..createSync(recursive: true);
  File('${android.path}/build.gradle.kts').writeAsStringSync(buildFile);
  return Process.run('bash', [
    'scripts/check-no-google.sh',
    '--gradle-deps',
    gradleFile.path,
    '--pub-deps',
    pubFile.path,
    '--android-dir',
    android.parent.path,
  ]);
}

String _variant(String name, [String extra = '']) =>
    '''
${name}RuntimeClasspath - Runtime classpath of '/$name'.
+--- io.flutter:flutter_embedding_$name:1.0.0-deb287481e
|    +--- androidx.lifecycle:lifecycle-common:2.7.0
|    +--- androidx.window:window-java:1.2.0
|    \\--- com.getkeepsafe.relinker:relinker:1.4.5
$extra\\--- org.jetbrains.kotlin:kotlin-stdlib:2.4.0
''';

final _cleanGradle = [_variant('debug'), _variant('profile'), _variant('release')].join('\n');

const _cleanPub = '''
Dart SDK 3.13.5
Flutter SDK 3.47.7
lukitas 1.0.0+1

dependencies:
- dio 5.11.1 [async collection http_parser meta mime path dio_web_adapter]
- flutter_riverpod 3.4.3 [collection flutter meta riverpod state_notifier]
- go_router 18.0.2 [collection flutter flutter_web_plugins logging meta]
''';

const _cleanBuildFile = '''
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}
''';

/// The listing with [dependency] added to the [variant]'s runtime classpath only.
String _gradleWith(String variant, String dependency) => [
  for (final name in ['debug', 'profile', 'release'])
    name == variant ? _variant(name, '+--- $dependency\n') : _variant(name),
].join('\n');

void main() {
  test('no Google dependency: clean listings pass', () async {
    final result = await _check();
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('no Google dependency: Play Services in a debug-only dependency fails', () async {
    final result = await _check(
      gradle: _gradleWith('debug', 'com.google.android.gms:play-services-base:18.5.0'),
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.android.gms:play-services-base'));
  });

  test('no Google dependency: Play Core fails with its name', () async {
    final result = await _check(
      gradle: _gradleWith('release', 'com.google.android.play:integrity:1.4.0'),
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.android.play:integrity'));
  });

  test('no Google dependency: Firebase and ML Kit fail with their names', () async {
    final result = await _check(
      gradle: _gradleWith('release', 'com.google.mlkit:text-recognition:16.0.1'),
      pub: '$_cleanPub- firebase_core 4.2.0 [firebase_core_platform_interface flutter meta]\n',
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.mlkit:text-recognition'));
    expect(result.stdout, contains('firebase_core'));
  });

  for (final dependency in [
    'com.google.ar:core:1.44.0',
    'com.google.android.ump:user-messaging-platform:3.1.0',
    'com.google.android.libraries.places:places:4.1.0',
    'com.google.android.datatransport:transport-runtime:3.3.0',
    'com.google.android.recaptcha:recaptcha:18.6.1',
    'com.android.billingclient:billing:7.1.1',
    'com.google.android.ads:mediation-test-suite:3.0.0',
    'com.crashlytics.sdk.android:crashlytics:2.10.1',
    'io.fabric.sdk.android:fabric:1.4.8',
    'com.huawei.hms:push:6.12.0.300',
  ]) {
    final name = dependency.substring(0, dependency.lastIndexOf(':'));
    test('no Google dependency: $name fails with its name', () async {
      final result = await _check(gradle: _gradleWith('release', dependency));
      expect(result.exitCode, 1, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains(name));
    });
  }

  test('no Google dependency: the Google Services plugin in a build file fails', () async {
    final result = await _check(
      buildFile: '$_cleanBuildFile\nplugins { id("com.google.gms.google-services") }\n',
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.gms.google-services'));
  });

  test('no Google dependency: the Crashlytics plugin in a build file fails', () async {
    final result = await _check(
      buildFile: '$_cleanBuildFile\nplugins { id("com.google.firebase.crashlytics") }\n',
    );
    expect(result.exitCode, 1);
    expect(result.stdout, contains('com.google.firebase.crashlytics'));
  });

  test('no Google dependency: a listing missing a variant is an error, not a pass', () async {
    final result = await _check(gradle: _variant('release'));
    expect(result.exitCode, 2);
  });

  test('no Google dependency: a missing listing is an error, not a pass', () async {
    final result = await Process.run('bash', [
      'scripts/check-no-google.sh',
      '--gradle-deps',
      '/nonexistent/gradle.txt',
      '--pub-deps',
      '/nonexistent/pub.txt',
    ]);
    expect(result.exitCode, 2);
  });
}
