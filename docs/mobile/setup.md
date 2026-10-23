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

The first Gradle build also installs `platforms;android-35` and `cmake;3.22.1` into the SDK: the
`jni` plugin (pulled in through `flutter_secure_storage`'s dependencies) builds against them.

## Physical phone

Enable Developer options and USB debugging on the phone, connect it by USB, accept the debugging prompt, then run `adb devices`. One device should be listed as `device`.

## Notes

- If Homebrew's `android-platform-tools` cask is also installed, `flutter doctor` warns about multiple `adb` binaries. Keep the SDK one first in `PATH` (the line above does), or uninstall the cask, so the adb server version is consistent.
- Do not commit anything from `~/development` or `~/Library/Android`. Only `apps/mobile/.flutter-version` and this file are tracked.
