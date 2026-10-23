import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/widget_snapshot.dart';
import 'package:lukitas/theme/tokens.g.dart';

// Checks that the Kotlin side of the home-screen widget (android/.../widget/) agrees with the Dart
// side it cannot import: the colours, the secure storage options, the snapshot version, the
// receivers' names, and the manifest entries.

const _widget = 'android/app/src/main/kotlin/com/andersonlaverde/lukitas/widget';
final _manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

String _kotlin(String file) => File('$_widget/$file').readAsStringSync();

int _argb(Color color) => color.toARGB32();

void main() {
  test("the widget's colours are the app's tokens, night and day", () {
    final source = _kotlin('WidgetContent.kt');
    final entries = RegExp(r'"(\w+)" to \(0x([0-9A-Fa-f]{8}) to 0x([0-9A-Fa-f]{8})\)')
        .allMatches(source)
        .toList();
    expect(entries, isNotEmpty);
    const night = LukitasColors.night;
    const day = LukitasColors.day;
    final tokens = <String, (Color, Color)>{
      'surface': (night.surface, day.surface),
      'ink': (night.ink, day.ink),
      'inkMuted': (night.inkMuted, day.inkMuted),
      'brand': (night.brand, day.brand),
      'onBrand': (night.onBrand, day.onBrand),
      'stroke': (night.stroke, day.stroke),
      'good': (night.good, day.good),
      'near': (night.near, day.near),
      'over': (night.over, day.over),
    };
    for (final entry in entries) {
      final name = entry.group(1)!;
      expect(tokens.containsKey(name), isTrue, reason: '$name is not a token here');
      final (n, d) = tokens[name]!;
      expect(int.parse(entry.group(2)!, radix: 16), _argb(n), reason: '$name at night');
      expect(int.parse(entry.group(3)!, radix: 16), _argb(d), reason: '$name by day');
    }
    expect(entries.map((e) => e.group(1)).toSet(), tokens.keys.toSet());
  });

  test('the refresh job reads secure storage with the very options Dart sends', () {
    final source = _kotlin('SecureSession.kt');
    final block = source.substring(source.indexOf('DART_DEFAULT_OPTIONS'));
    final kotlin = {
      for (final m in RegExp(r'"(\w+)" to "([^"]*)"').allMatches(block)) m.group(1)!: m.group(2)!,
    };
    expect(kotlin, AndroidOptions.defaultOptions.toMap());
  });

  test('the refresh job reads the keys the app writes', () {
    final source = _kotlin('SecureSession.kt');
    expect(source, contains('TOKEN_KEY = "session.token"'));
    expect(source, contains('SERVER_KEY = "setting.server"'));
  });

  test('both sides agree on the snapshot: key, version, receivers', () {
    final snapshot = _kotlin('WidgetSnapshot.kt');
    expect(snapshot, contains('KEY = "$widgetSnapshotKey"'));
    expect(snapshot, contains('VERSION = $widgetSnapshotVersion'));
    for (final receiver in widgetReceivers) {
      final name = receiver.split('.').last;
      expect(_manifest, contains('android:name=".widget.$name"'));
      expect(
        File('$_widget/${name.replaceFirst('Receiver', '')}.kt').readAsStringSync(),
        contains('class $name'),
      );
    }
  });

  test('the deep links: lukitas://add and capture, on the app, not openable from a web page', () {
    final filter = RegExp(
      r'<intent-filter>((?:(?!</intent-filter>).)*android:scheme="lukitas"(?:(?!</intent-filter>).)*)</intent-filter>',
      dotAll: true,
    ).firstMatch(_manifest)!.group(1)!;
    expect(filter, contains('android:host="add"'));
    expect(filter, contains('android:host="capture"'));
    expect(filter, contains('android.intent.action.VIEW'));
    expect(filter, isNot(contains('BROWSABLE')));
  });

  test('the Quick Settings tile only the system can bind', () {
    expect(_manifest, contains('android:name=".tile.CaptureTileService"'));
    expect(_manifest, contains('android:permission="android.permission.BIND_QUICK_SETTINGS_TILE"'));
    expect(_manifest, contains('android.service.quicksettings.action.QS_TILE'));
  });
}
