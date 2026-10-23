import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One licence text that Flutter's own registry does not know. Flutter collects the LICENSE files
/// of the app's Dart packages and its own engine and framework by itself (that is what About's
/// licence page lists); everything else the app ships is added here: the voice models, the speech
/// engine and the Android libraries (Kotlin, not Dart), and the app's own sounds.
class _Extra {
  const _Extra(this.packages, this.notice, this.textAsset);

  final List<String> packages;

  /// Who made it and where it comes from, above the licence text.
  final String notice;

  /// The licence text, in assets/licenses.
  final String textAsset;
}

const _apache = 'assets/licenses/apache-2.0.txt';
const _agpl = 'assets/licenses/agpl-3.0.txt';

const _extras = [
  _Extra(
    ['vosk-model-small-es-0.42'],
    'The Spanish speech model of quick capture, by Alpha Cephei Inc., under the Apache License '
    '2.0 (https://alphacephei.com/vosk/models). It is not in the app: it is downloaded to the '
    'phone when the person agrees, and it recognises speech on the phone alone.',
    _apache,
  ),
  _Extra(
    ['vosk-model-small-en-us-0.15'],
    'The English speech model of quick capture, by Alpha Cephei Inc., under the Apache License '
    '2.0 (https://alphacephei.com/vosk/models). It is not in the app: it is downloaded to the '
    'phone when the person agrees, and it recognises speech on the phone alone.',
    _apache,
  ),
  _Extra(
    ['vosk-android 0.3.75'],
    'The Vosk speech engine (https://github.com/alphacep/vosk-api), by Alpha Cephei Inc., under '
    'the Apache License 2.0.',
    _apache,
  ),
  _Extra(
    ['JNA 5.18.1'],
    'Java Native Access (https://github.com/java-native-access/jna), which Vosk reaches its '
    'native library through. It is dual-licensed under the Apache License 2.0 or the LGPL '
    '2.1; Lukitas uses it under the Apache License 2.0.',
    _apache,
  ),
  _Extra(
    [
      'AndroidX',
      'Kotlin standard library',
      'Tink',
      'Gson',
      'ReLinker',
      'Guava ListenableFuture',
      'JSR 305',
      'Error Prone annotations',
    ],
    'The Android libraries the app is built with: AndroidX (Jetpack, Compose runtime, Glance, '
    'WorkManager, Room, DataStore and Credentials, by the Android Open Source Project), '
    'Kotlin (JetBrains), Tink and Gson (Google), ReLinker (KeepSafe), Guava ListenableFuture, '
    'JSR 305 and Error Prone annotations. All of them are under the Apache License 2.0. None '
    'of them is Google Play Services or Firebase.',
    _apache,
  ),
  _Extra(
    ['Lukitas feedback sounds'],
    'The sounds Lukitas plays when you add a movement, pay one, undo, or come near a limit are '
    'original work made for Lukitas: a few plain sine tones, with no third-party samples. '
    'They are released under the licence of the app itself, the GNU Affero General Public '
    'License 3.0 (https://github.com/andirsun/lukas).',
    _agpl,
  ),
  _Extra(
    ['Lukitas'],
    'Lukitas is free software, under the GNU Affero General Public License 3.0. Its source code '
    'is at https://github.com/andirsun/lukas.',
    _agpl,
  ),
];

/// The licences Flutter does not collect by itself, as [LicenseEntry]s (text read from [bundle]).
Stream<LicenseEntry> extraLicenseEntries(AssetBundle bundle) async* {
  for (final extra in _extras) {
    final text = await bundle.loadString(extra.textAsset);
    yield LicenseEntryWithLineBreaks(extra.packages, '${extra.notice}\n\n$text');
  }
}

var _registered = false;

/// Adds [extraLicenseEntries] to Flutter's registry, once, so About's licence page lists them with
/// the packages'. Called at the start of the app.
void registerExtraLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() => extraLicenseEntries(rootBundle));
}
