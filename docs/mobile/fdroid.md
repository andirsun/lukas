# F-Droid: what is ready and what a submission still needs

Lukitas is built to be listed on F-Droid, but nothing has been submitted (spec section 1: "no F-Droid submission"). This is the ledger for the day it is: what is already in the repo, what was measured, and what the submission will have to solve. Nothing below is solved yet.

## Ready now

- **No Google, no trackers.** `scripts/check-no-google.sh` (CI) fails on Play Services, Firebase, ML Kit, Play Core or any other proprietary artifact in any variant's resolved classpath. No analytics, no crash reporter. Permissions are an allowlist (`scripts/check-permissions.sh`).
- **Licences.** AGPL-3.0; every Dart and Android dependency has a licence entry in About (`scripts/check-licenses.sh`). Voice models and sounds are listed too.
- **Metadata in the repo:** `apps/mobile/fastlane/metadata/android/{es-ES,en-US}`: title, short and full description, six phone screenshots each (emulator captures with made-up data), and a changelog named for each version code of the first release. `scripts/check-fastlane.sh` checks F-Droid's limits. There is no `icon.png` or feature graphic: F-Droid takes the launcher icon from the APK. When submitting, confirm that F-Droid finds the folder under the app's subdirectory (`apps/mobile`); if it only looks at the repository root, the recipe needs `subdir: apps/mobile` and a check, or the folder has to be linked at the root.
- **Versions:** `mobile-vX.Y.Z` tags, `versionCode = (X*10000 + Y*100 + Z) * 10 + ABI digit` (`release.md`). For the recipe: `UpdateCheckMode: Tags` with a `mobile-v` pattern, one build entry per ABI, and `VercodeOperation` of `%c * 10 + 1` (`armeabi-v7a`) and `%c * 10 + 2` (`arm64-v8a`) over the base code. The build passes `--build-name` and `--build-number` like `release.sh` does (the tag's `X.Y.Z` and `X*10000 + Y*100 + Z`).
- **Split APKs** per ABI (`--split-per-abi --target-platform android-arm,android-arm64`), about 30 MB each instead of a 60 MB universal one.
- **Pinned toolchain:** the Flutter version (`.flutter-version`, `pubspec.lock` pins every pub package), the Gradle wrapper, Android Gradle Plugin 9.1.0, Kotlin 2.4.0, NDK `28.2.13676358` (what Flutter 3.47.7 asks for), and exact Gradle dependency versions.

## Reproducibility, measured

`scripts/check-reproducible.sh` builds the unsigned release APKs twice from clean (`flutter clean` and a fresh `pub get` between them) and compares them byte for byte. Measured on the founder's Mac (Apple Silicon, Flutter 3.47.7, JDK 17.0.21, AGP 9.1.0) on the tree of the commit that added these scripts:

| Comparison | arm64-v8a | armeabi-v7a |
|---|---|---|
| Two clean builds, same checkout path | identical | identical |
| The same commit built in two different checkout paths | **differs** | **differs** |

The APKs themselves are normalised by AGP (entry timestamps fixed, no signature, nothing from the clock), so the container is stable. Across checkout paths, exactly two files differ, in both ABIs:

- `lib/<abi>/libapp.so`, the Dart AOT snapshot: it contains the absolute `file:///…/.dart_tool/flutter_build/dart_plugin_registrant.dart` of the build tree and a name hash derived from it (`_PluginRegistrant@<hash>`), and everything after it shifts.
- `lib/<abi>/libdartjni.so`, built by CMake from the `jni` plugin: 19 bytes differ (a build id or path-derived data; not investigated further).

What this means for F-Droid: F-Droid builds at its own fixed path (under `build/<applicationId>` of its build server) and signs the result with its own key, so its APK is not the founder's. For F-Droid's reproducible-build verification (publishing the developer's signature on F-Droid's build, `Binaries:` in the recipe) the founder's build has to be made at the same absolute path, for example in a container or VM that mounts the checkout there. Without that, the founder's APK and F-Droid's are two different, individually reproducible builds, and F-Droid ships its own: users who switch between them have to reinstall, and `ANDROID_CERT_SHA256` lists both fingerprints (`release.md`). Whether to chase path-independence (for instance by asking Flutter for a stable `--source` mapping, which does not exist as a flag today) or to build in a fixed-path container is a later decision. The builds also depend on a warm Gradle cache only for speed, not for the bytes. Not yet measured: a different machine or operating system (Linux, which is what F-Droid runs).

## What the submission will have to solve

### Native libraries from Maven that are prebuilt

`com.alphacephei:vosk-android:0.3.75` and JNA `net.java.dev.jna:jna:5.18.1` are `.aar` files from Maven Central that carry compiled native code. F-Droid wants native code built from source, so each becomes a source library (`srclibs`) built in the recipe's `prebuild`, and the Gradle dependency is replaced by what was built.

| Artifact | Prebuilt contents | In our APK | Source |
|---|---|---|---|
| `vosk-android:0.3.75` | `jni/{arm64-v8a,armeabi-v7a,x86,x86_64}/libvosk.so` (9 to 10 MB each) and a small `classes.jar` | `lib/arm64-v8a/libvosk.so` (10 MB), `lib/armeabi-v7a/libvosk.so` (9 MB): the biggest part of the APK after the Flutter engine | `https://github.com/alphacep/vosk-api`, the `android/` directory (the POM's `scm` URL). `libvosk.so` is Kaldi plus OpenFst plus OpenBLAS and CLAPACK, cross-built with the NDK by the scripts in `android/lib` (`build-kaldi.sh`, `build-vosk.sh`). Heavy: it compiles those dependencies from their own sources. The `0.3.75` tag name and whether the script's output matches the published AAR byte for byte are to be checked |
| `jna:5.18.1` (Vosk reaches its library through it, by reflection) | `jni/<abi>/libjnidispatch.so` for eight ABIs (`armeabi`, `mips` and `mips64` included) and `classes.jar` | `lib/arm64-v8a/libjnidispatch.so`, `lib/armeabi-v7a/libjnidispatch.so` | `https://github.com/java-native-access/jna`, built with Ant and the NDK for `android-aarch64` and `android-armv7`; the Java classes come from the same source |

Things to settle when doing it:

- how the built `libvosk.so`, `libjnidispatch.so` and their Java classes replace the Maven artifacts in Gradle (a local Maven repository or `flatDir` populated by the recipe, or an `includeBuild`), and that `scripts/check-no-google.sh` and `assets/licenses/android-libraries.json` (which lists both under their POM licences) still agree;
- JNA is dual-licensed (Apache-2.0 or LGPL-2.1): the About page already says so;
- the `proguard-rules.pro` keeps for `com.sun.jna.**` stay as they are;
- Vosk is built for four ABIs upstream and we ship two: the recipe builds only `arm64-v8a` and `armeabi-v7a`, which also shortens the Kaldi build.

### Other native code in the APK

| Library | Where it comes from | Note |
|---|---|---|
| `libflutter.so` | the Flutter engine, from the pinned Flutter SDK | F-Droid has an established recipe for Flutter apps (a `flutter` srclib at the pinned version); check the current practice for the engine artifacts when submitting |
| `libapp.so` | our Dart code, AOT-compiled in the build | deterministic for a fixed path, see above |
| `libdartjni.so` | the `jni` pub package, built by CMake in the build (it pulls `platforms;android-35` and `cmake;3.22.1` into the SDK, setup.md) | the recipe's build server needs those SDK pieces; the package arrives through `flutter_secure_storage` |

### Other items

- **The Gradle wrapper jar** is not committed (`android/.gitignore`): Flutter generates it. F-Droid checks wrapper jars against known checksums; have the recipe use the one Flutter writes, or commit it, and verify the check passes.
- **No Gradle dependency locking.** Versions are exact in `build.gradle.kts`, but the transitive ones are what Maven metadata resolves to on the day; a lockfile (`dependencyLocking`) would make that explicit for the recipe. It is not set up.
- **Voice models are downloaded at runtime** (`voice-models-v1` release on GitHub, SHA-256 checked, Apache-2.0, about 40 MB each) and are not in the APK. They are data, not code; mention it in the submission, since reviewers may ask about runtime downloads. The release `voice-models-v1` does not exist yet (the voice spike's models are served by a stand-in in the tests).
- **Anti-features:** none expected. No ads, no tracking, no non-free dependencies, and the server it talks to is free software (AGPL). By default it talks to the author's personal install (`app-lukas.andersonlaverde.com`); the Settings screen changes that. If a reviewer reads that as `NonFreeNet`, the answer is that the server's code is in this repository and anyone can run it (`deploy/personal`).
- **Signing:** F-Droid signs with its own key (unless reproducibility lets it publish ours). That key's fingerprint goes into `ANDROID_CERT_SHA256` next to the founder's, or App Links and passkeys do not work for F-Droid users.
- **Package name** is `com.andersonlaverde.lukitas` (founder decision, spec section 9): it cannot change once published.
