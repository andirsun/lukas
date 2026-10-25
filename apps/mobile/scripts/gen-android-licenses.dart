// ignore_for_file: file_names, avoid_print

/// Generates assets/licenses/android-libraries.json: every Android library on the release
/// classpath (what the APK ships), with the licence its POM declares. About lists them from it
/// (lib/settings/licenses.dart), so the attribution follows the build instead of a hand-kept list.
///
/// A library whose POM names no licence (and none of its parents does), or one this script has no
/// decision for, fails the run: someone looks at it and decides.
///
/// Usage, from apps/mobile (after a Gradle build, so the POMs are in Gradle's cache):
///   dart run scripts/gen-android-licenses.dart            writes the file
///   dart run scripts/gen-android-licenses.dart --check    fails when the committed file differs
///   ... --gradle-output FILE                               a recorded Gradle listing, not a run
/// Exit codes: 0 fine, 1 the file is stale (--check) or a licence needs a decision, 2 no listing
/// or no POM.
library;

import 'dart:io';

import 'android_licenses_lib.dart';

const outputPath = 'assets/licenses/android-libraries.json';

Never _fail(String message, [int code = 2]) {
  stderr.writeln(message);
  exit(code);
}

String _gradleOutput(List<String> args) {
  final at = args.indexOf('--gradle-output');
  if (at >= 0 && at + 1 < args.length) return File(args[at + 1]).readAsStringSync();
  final result = Process.runSync('./gradlew', [
    '-q',
    ':app:dependencies',
    '--configuration',
    'releaseRuntimeClasspath',
  ], workingDirectory: 'android');
  if (result.exitCode != 0) _fail('Gradle failed:\n${result.stderr}');
  return result.stdout as String;
}

String _gradleCache() {
  final home =
      Platform.environment['GRADLE_USER_HOME'] ?? '${Platform.environment['HOME']}/.gradle';
  return '$home/caches/modules-2/files-2.1';
}

/// The POM of group:artifact:version from Gradle's cache.
String _pom(String group, String artifact, String version) {
  final dir = Directory('${_gradleCache()}/$group/$artifact/$version');
  if (dir.existsSync()) {
    for (final entry in dir.listSync(recursive: true)) {
      if (entry is File && entry.path.endsWith('/$artifact-$version.pom')) {
        return entry.readAsStringSync();
      }
    }
  }
  _fail('No POM for $group:$artifact:$version in ${_gradleCache()}: build the app first.');
}

/// The licence names of a POM, following its parents when it names none.
List<String> _licenses(String group, String artifact, String version) {
  var pom = _pom(group, artifact, version);
  for (var depth = 0; depth < 8; depth++) {
    final own = pomLicenses(pom);
    if (own.isNotEmpty) return own;
    final parent = pomParent(pom);
    if (parent == null) break;
    pom = _pom(parent.$1, parent.$2, parent.$3);
  }
  return const [];
}

void main(List<String> args) {
  final libraries = <AndroidLibrary>[];
  for (final resolved in resolvedLibraries(_gradleOutput(args))) {
    final [group, artifact] = resolved.id.split(':');
    final names = _licenses(group, artifact, resolved.version);
    try {
      libraries.add(AndroidLibrary(resolved.id, resolved.version, normalizeLicenses(names)));
    } on UnknownLicense {
      _fail(
        '${resolved.id} ${resolved.version}: licence $names needs a decision in scripts/android_licenses_lib.dart',
        1,
      );
    }
  }
  if (libraries.isEmpty) _fail('No libraries found in the Gradle listing.');
  final text = renderLibraries(libraries);
  final file = File(outputPath);
  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != text) {
      _fail(
        '$outputPath is stale: the release classpath or its POMs changed. Run '
        '`dart run scripts/gen-android-licenses.dart` and commit the result.',
        1,
      );
    }
    print('$outputPath matches the ${libraries.length} libraries of the release classpath.');
    return;
  }
  file.writeAsStringSync(text);
  print('Wrote ${libraries.length} libraries to $outputPath.');
}
