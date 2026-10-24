# Mobile toolchain setup (macOS, Apple Silicon)

How the Stage 3 Android app toolchain was installed on the founder's Mac, with exact versions, so it can be reproduced. Everything lives under the user's home directory. Android Studio is not used.

## Versions

| Component | Version | Location |
|---|---|---|
| Flutter (stable) | 3.47.7 (Dart 3.13.5, DevTools 2.60.0, engine `deb287481e`) | `~/development/flutter` |
| JDK | Eclipse Temurin 17.0.21+9 (aarch64) | `~/development/jdk/jdk-17.0.21+9/Contents/Home` |
| Android command-line tools | `commandlinetools-mac-15641748_latest` (sdkmanager 21.0) | `~/Library/Android/sdk/cmdline-tools/latest` |
| platform-tools (adb) | 37.0.1 | `~/Library/Android/sdk/platform-tools` |
| Platform | `platforms;android-36` (rev 2) | `~/Library/Android/sdk/platforms/android-36` |
| Build-tools | `build-tools;36.0.0` | `~/Library/Android/sdk/build-tools/36.0.0` |
| NDK | `ndk;28.2.13676358` (r28c), the version Flutter 3.47.7 sets in `flutter.ndkVersion` | `~/Library/Android/sdk/ndk/28.2.13676358` |
| Emulator | 37.2.12 | `~/Library/Android/sdk/emulator` |
| System image | `system-images;android-36;default;arm64-v8a` (AOSP, no Google services) | `~/Library/Android/sdk/system-images/android-36/default/arm64-v8a` |

The Flutter version is pinned in `apps/mobile/.flutter-version`. Flutter 3.47.7 uses compileSdk 36, targetSdk 36 and minSdk 24.

The emulator system image is development tooling only. It is not an app dependency.

## Reproduce

### 1. JDK 17

The Homebrew cask `temurin@17` runs a `.pkg` installer through `sudo`, which needs an interactive password. To avoid that, the official Temurin tarball is unpacked in the home directory instead (no system changes):

```sh
mkdir -p ~/development/jdk && cd /tmp
curl -fsSL -O https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.21.9/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.21_9.tar.gz
echo "78b08c7f5a0598242d5719c022e19479cb4a3aa45c37c19726a757a469ed1c15  OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.21_9.tar.gz" | shasum -a 256 -c
tar -xzf OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.21_9.tar.gz -C ~/development/jdk
```

(`brew install --cask temurin@17` is the equivalent if you can type your password.)

### 2. Flutter

```sh
mkdir -p ~/development && cd ~/development
curl -fsSL -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.47.7-stable.zip
unzip -q flutter_macos_arm64_3.47.7-stable.zip && rm flutter_macos_arm64_3.47.7-stable.zip
~/development/flutter/bin/flutter --disable-analytics   # optional: opt out of telemetry
```

### 3. Android SDK

```sh
export JAVA_HOME=~/development/jdk/jdk-17.0.21+9/Contents/Home   # sdkmanager 21 needs Java 17+
export PATH="$JAVA_HOME/bin:$PATH"

mkdir -p ~/Library/Android/sdk/cmdline-tools && cd /tmp
curl -fsSL -O https://dl.google.com/android/repository/commandlinetools-mac-15641748_latest.zip
unzip -q commandlinetools-mac-15641748_latest.zip -d ~/Library/Android/sdk/cmdline-tools
mv ~/Library/Android/sdk/cmdline-tools/cmdline-tools ~/Library/Android/sdk/cmdline-tools/latest

SM=~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager
$SM --sdk_root=$HOME/Library/Android/sdk --licenses     # read and accept
$SM --sdk_root=$HOME/Library/Android/sdk \
  "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
  "ndk;28.2.13676358" "emulator" "system-images;android-36;default;arm64-v8a"
```

### 4. Tell Flutter where things are

```sh
flutter config --jdk-dir "$HOME/development/jdk/jdk-17.0.21+9/Contents/Home" \
               --android-sdk "$HOME/Library/Android/sdk"
```

### 5. PATH

Add to `~/.zshrc`:

```sh
export PATH="$HOME/development/flutter/bin:$HOME/Library/Android/sdk/cmdline-tools/latest/bin:$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"
```

`JAVA_HOME` is deliberately not exported globally (the system `java` is still 11). Flutter and Gradle use the JDK set by `flutter config --jdk-dir`. When you run `sdkmanager` or `avdmanager` by hand, prefix them with `JAVA_HOME=~/development/jdk/jdk-17.0.21+9/Contents/Home`.

### 6. Check

```sh
flutter doctor -v
```

Expected: Flutter and the Android toolchain are OK. Xcode, Chrome and Android Studio may show warnings or be missing; the Android app does not need them.

## The time zone table

`apps/mobile/lib/settings/zone_countries.dart` is generated: the time zones Settings offers (the web's 418, in ICU's
spelling, which is what the API stores), the country of each and the countries' names. Rerun it only to move to
another tz or ICU version:

```sh
cd apps/mobile
node tool/gen_zone_countries.mjs > lib/settings/zone_countries.dart && dart format lib/settings/zone_countries.dart
flutter test test/settings/settings_model_test.dart
```

It is pinned to Node 22 with ICU 78.2 (tz 2025c) and stops on any other, or if the ids are not exactly
`Intl.supportedValuesOf("timeZone")`. The countries come from `tool/zone.tab` (tz 2026d), kept next to the script. To
update, change the versions at the top of the script and replace `tool/zone.tab` together. The app's clock reads every
id: they must all be in the `timezone` package's `latest_all` database (the test checks).

## Emulator (AVD `lukitas-api36`)

Create it once:

```sh
export JAVA_HOME=~/development/jdk/jdk-17.0.21+9/Contents/Home
echo no | avdmanager create avd -n lukitas-api36 \
  -k "system-images;android-36;default;arm64-v8a" -d pixel_8
```

Run it:

```sh
emulator -avd lukitas-api36                                    # with a window
emulator -avd lukitas-api36 -no-window -no-audio -gpu swiftshader_indirect   # headless, for integration tests
adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 1; done'
flutter devices
adb emu kill                                                   # stop it
```

The headless command was verified: it boots to `sys.boot_completed=1` as `emulator-5554` with SDK 36.

## Integration tests against the dev stack

The tests in `apps/mobile/integration_test` drive the app on the emulator against the dev stack
(`docker compose up -d` at the repo root: API on port 3000, Postgres, Mailpit on 8025). The emulator
reaches the Mac at `10.0.2.2`; debug builds allow plain HTTP for it.

```sh
docker compose up -d                                           # from the repo root
emulator -avd lukitas-api36 -no-window -no-audio -gpu swiftshader_indirect &
adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 1; done'
cd apps/mobile
flutter test integration_test -d emulator-5554 \
  --dart-define=LUKITAS_SERVER=http://10.0.2.2:3000 \
  --dart-define=MAILPIT_URL=http://10.0.2.2:8025
```

`apps/mobile/scripts/run-integration-tests.sh` runs every file below in turn on a running emulator (it refuses anything that is not `emulator-*`), installing the app first in the notification-permission state each file needs; CI's `mobile-emulator` job runs it. Start the dev stack on the real clock (no `E2E_NOW`), as CI does: the emulator's clock is real, and every test makes its own data from the device's today.

They read sign-in codes and links from Mailpit, as the web's e2e suite does. The API allows 5 code
requests per 10 minutes from one address, and every run from the emulator comes from the same one:
running the suite more than twice in 10 minutes gets `too_many_requests`.

`integration_test/capture_test.dart` replaces the speech engine with a fixed transcript (spec
section 6.4). The real engine's plumbing (model download, SHA-256 check, unzip, Vosk load, both
recognizers, stop) has its own test, skipped unless a stand-in for the `voice-models-v1` release
serves the official model zips (the emulator has no real microphone, so it hears silence):

```sh
python3 -m http.server 8765 --directory <folder with vosk-model-small-es-0.42.zip>
# once the app is installed by the run below (the test waits for the download):
adb -s emulator-5554 shell pm grant com.andersonlaverde.lukitas android.permission.RECORD_AUDIO
flutter test integration_test/voice_engine_test.dart -d emulator-5554 \
  --dart-define=VOICE_MODELS_URL=http://10.0.2.2:8765
```

`integration_test/categories_test.dart` creates a category from home's Categorías tab, renames it and changes its colour in the detail, archives it (after the question) and restores it, checking the server after each step. It needs the notification permission given, like the others.

`integration_test/import_test.dart` imports a Budge file through the real `lukitas/files` channel (`android/.../files/FilesChannel.kt`): the system's document picker cannot be driven from a test, so the debug build lets the test hand the next pick a file in the app's cache (`injectPick`, refused by a release build), and that file goes through the same bounded, off-the-main-thread read as a picked document. It checks a file over 5 MB (refused by the channel, nothing sent), a malformed one (the API's refusal), the sample (22 rows: the preview, nothing in the account until the confirm, then the transactions, the categories and the file's currency on the server), the same file again, and a 2,000-row file (imported whole, with the longest gap between frames kept short). The real picker (`ACTION_OPEN_DOCUMENT`) and the share sheet are not exercised by it.

`integration_test/welcome_test.dart` signs in as a new email user (the code comes from Mailpit) and goes through the welcome: the currency (dollars, wherever the phone is), a restart of the app in the middle (the welcome is where it was left), "No, empiezo de cero", the categories, a budget, and home; then it checks the account on the server (`onboardingCompletedAt`, the currency, the suggested categories, the budget) and that a later start goes straight home. A second test takes "Entrar directo". It uses two code requests, so give it its own 10 minutes of the sign-in limit. An account with no `onboardingCompletedAt` is sent to the welcome after any email sign-in, so `entry_test.dart` waits for it there; a guest, and a guest that saves its progress with an email, land on home.

`integration_test/widget_test.dart` covers the home-screen widget (Task 15): it presses the
widget's ＋, 🎤 and body the way the widget does (the very intent `launch/LaunchLinks.kt` builds, started
through the debug-only `lukitas/test` channel; the body also with the `glance-action:/CALLBACK?...`
intent Glance used to give it, which showed "Page Not Found" while the app ran) and runs the refresh job once through WorkManager,
which reads the session where the app keeps it and asks the dev stack for the summary; then it
signs out and checks the widget keeps no figure. To look at the widgets themselves, long-press the
emulator's home screen, open Widgets and drag a Lukitas one out; the Quick Settings tile is added
with `adb -s emulator-5554 shell cmd statusbar add-tile com.andersonlaverde.lukitas/.tile.CaptureTileService`.

With the voice models served as for `voice_engine_test.dart` (and the microphone granted),
`widget_test.dart` also runs a test with the real speech engine: 🎤 tapped, the sentence ended, 🎤
tapped again, and the second listen must go on listening (not end at once, unheard). Add
`--dart-define=VOICE_MODELS_URL=http://10.0.2.2:8765` to run it; without it, it is skipped.

`integration_test/voice_latency_test.dart` times tap to listening with the real engine (cold, then
warm), against the same stand-in for the models as above, and prints `LATENCY` lines. The emulator
has no microphone, so it times the plumbing. `--dart-define=VOICE_USED=true` is a person who has
captured before (the model is loaded at the app's start):

```sh
python3 -m http.server 8765 --directory <folder with both model zips>
adb -s emulator-5554 install -r -t -g build/app/outputs/flutter-apk/app-debug.apk
flutter test integration_test/voice_latency_test.dart -d emulator-5554 \
  --dart-define=LUKITAS_SERVER=http://10.0.2.2:3000 \
  --dart-define=VOICE_MODELS_URL=http://10.0.2.2:8765 --dart-define=VOICE_USED=true
```

The Android JVM tests (`cd apps/mobile/android && ./gradlew :app:testDebugUnitTest`) include the
widget's Glance rendering tests on Robolectric, which downloads its Android image from Maven
Central on the first run.

`integration_test/notices_test.dart` covers the two local notices (Task 16). The first test needs the
notification permission not yet given (a fresh install), the second needs it given: install with
`adb -s emulator-5554 install -r -g build/app/outputs/flutter-apk/app-debug.apk` and
`adb -s emulator-5554 shell pm grant com.andersonlaverde.lukitas android.permission.POST_NOTIFICATIONS`
right before it. It gives the profile a zone where it is about noon ("Hoy vence…" never goes out before 9:00 there), makes two recurring payments due today through the API, brings the app back to the foreground so it schedules the job, runs the "Hoy vence…" job
once through WorkManager, checks the notice's text, and taps it (the same PendingIntent the shade
sends) from Settings, expecting home. With `--dart-define=TAP_BY_HAND=true` it waits for you to tap
the real notification on the shade (`adb shell cmd statusbar expand-notifications`).

`integration_test/feedback_test.dart` needs no dev stack: it checks that the sound files are found in
the APK and load into the `SoundPool`, and that the motor channel answers. How a haptic *feels* is
for a real phone (an emulator has no motor): tap through the add sheet, a swipe and a quick capture
there.

`integration_test/settings_test.dart` needs no dev stack either: it checks that the licences About adds
(the voice models, the speech engine, the sounds) are registered at start, and that "Más en la web"
refuses anything but http and https. `integration_test/entry_test.dart` includes the claim: a guest
with a movement saves their progress to an email from Mailpit and keeps the movement. It also checks
that a sign-in started in the app writes its link with `from=app` (the app sends `x-lukas-client:
android`), and that the `intent://` form the web page's "Abrir en Lukitas" offers (scheme `http` here,
`https` in the product) starts the app and signs in. The emulator has no passkey provider, so the
passkey on the email screen is covered by the widget tests, and by hand with Proton Pass on a phone.

Why the permission matters: a fresh install has not been given the notification permission, so the question a guest is asked about notices (Task 16) covers the screen and the other files' taps miss. `flutter test` uninstalls the app when it ends, so each file needs the app installed by hand first: `adb install -r -t -g build/app/outputs/flutter-apk/app-debug.apk` and `adb shell pm grant com.andersonlaverde.lukitas android.permission.POST_NOTIFICATIONS` (the notices file's two tests are run separately, with `--plain-name`, one with the permission revoked and one with it granted).

The first Gradle build also installs `platforms;android-35` and `cmake;3.22.1` into the SDK: the
`jni` plugin (pulled in through `flutter_secure_storage`'s dependencies) builds against them.

## Physical phone

Enable Developer options and USB debugging on the phone, connect it by USB, accept the debugging prompt, then run `adb devices`. One device should be listed as `device`.

## Notes

- If Homebrew's `android-platform-tools` cask is also installed, `flutter doctor` warns about multiple `adb` binaries. Keep the SDK one first in `PATH` (the line above does), or uninstall the cask, so the adb server version is consistent.
- Do not commit anything from `~/development` or `~/Library/Android`. Only `apps/mobile/.flutter-version` and this file are tracked.
