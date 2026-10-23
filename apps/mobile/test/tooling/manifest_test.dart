import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('backup is off: the Keystore-bound session token cannot be restored on another device', () {
    expect(manifest, contains('android:allowBackup="false"'));
  });

  test('the microphone is asked for (quick capture), and no Google speech service is used', () {
    expect(manifest, contains('android.permission.RECORD_AUDIO'));
    final kotlin = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.kt'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    expect(kotlin, contains('org.vosk'));
    // Android's SpeechRecognizer sends audio to whichever service the phone has: Google's, mostly.
    expect(kotlin, isNot(contains('SpeechRecognizer')));
  });

  test('the motor is asked for (the haptics), and sounds play without Play Services', () {
    expect(manifest, contains('android.permission.VIBRATE'));
    final kotlin = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.kt'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    // Composition primitives on Android 11 and up, a waveform below (spec section 6.2).
    expect(kotlin, contains('VibrationEffect.startComposition'));
    expect(kotlin, contains('areAllPrimitivesSupported'));
    expect(kotlin, contains('createWaveform'));
    // The platform's own SoundPool: no audio plugin, nothing from Google.
    expect(kotlin, contains('SoundPool'));
  });
}
