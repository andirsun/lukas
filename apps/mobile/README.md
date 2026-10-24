# Lukitas for Android

The Flutter app (spec: `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md`). Toolchain setup: `docs/mobile/setup.md`. The Flutter version is pinned in `.flutter-version`.

```sh
flutter pub get                 # also generates AppLocalizations from lib/l10n/*.arb
flutter analyze
flutter test                    # everything, golden images included
flutter test --exclude-tags golden    # what CI runs: goldens are pixels from the Mac that made them
flutter test --update-goldens --tags golden    # after a deliberate change to how a screen looks
flutter build apk --debug
```

The integration tests (`integration_test/`) run on the emulator against the dev stack: see "Integration tests against the dev stack" in `docs/mobile/setup.md`.

## Generated code (committed; CI fails when stale)

- `lib/theme/tokens.g.dart`, from `docs/design/system/project/tokens.json`: `dart run scripts/gen-tokens.dart`.
- `lib/api/gen`, the API client, from the API's OpenAPI document (built from `apps/api`, no server): `scripts/gen-api.sh`. Needs `pnpm install` at the repo root and Java 11 or newer.

## No Google, and deliberate permissions

The app takes no Google Play Services, Firebase, ML Kit, Play Core, ARCore or other proprietary dependency, so F-Droid can build it.

- `scripts/check-no-google.sh` scans the Gradle build files for the Google Services and Firebase plugins, then resolves every variant's runtime classpath (debug, profile, release) and the pub packages, and fails on any banned name.
- `scripts/test-no-google-probes.sh` adds banned dependencies to a temporary copy of the app and expects the check to catch each one.
- `scripts/check-permissions.sh`, after `flutter build apk --release`, checks that the release APK asks for INTERNET and for no permission outside its allowlist.
- `scripts/check-licenses.sh`, after `flutter build apk --release`, checks that the APK's licence file (`NOTICES.Z`, which About's licence page shows) has an entry for every package under `dependencies:`. It also fails when `assets/licenses/android-libraries.json` (the Android libraries About lists, each under the licence its POM declares) is not what the release classpath resolves to: regenerate it with `dart run scripts/gen-android-licenses.dart`. The voice models, the speech engine, the sounds and the app are added by `lib/settings/licenses.dart`.

CI runs all four.

## Release, F-Droid metadata and the emulator suite

`docs/mobile/release.md` has the procedure; `docs/mobile/fdroid.md` has what an F-Droid submission will need.

- `scripts/release.sh` builds, signs and verifies the split release APKs with the founder's key (from environment variables only) and prints the certificate's `ANDROID_CERT_SHA256`. `scripts/release-lib.sh` holds the version scheme and the fingerprint format; `scripts/test-release.sh` tests them.
- `scripts/check-reproducible.sh` builds the unsigned release APKs twice and compares them.
- `scripts/check-fastlane.sh` checks `fastlane/metadata/android` (es-ES, en-US) against F-Droid's limits.
- `scripts/run-integration-tests.sh` runs `integration_test/` on a running emulator against the dev stack.
- The Kotlin unit tests: `cd android && ./gradlew :app:testDebugUnitTest`.

CI runs all of them but the signed build (`release.sh` runs there with a throwaway key) and the reproducibility check.
