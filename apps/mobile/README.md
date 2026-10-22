# Lukitas for Android

The Flutter app (spec: `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md`). Toolchain setup: `docs/mobile/setup.md`. The Flutter version is pinned in `.flutter-version`.

```sh
flutter pub get                 # also generates AppLocalizations from lib/l10n/*.arb
flutter analyze
flutter test
flutter build apk --debug
```

## Generated code (committed; CI fails when stale)

- `lib/theme/tokens.g.dart`, from `docs/design/system/project/tokens.json`: `dart run scripts/gen-tokens.dart`.
- `lib/api/gen`, the API client, from the API's OpenAPI document (built from `apps/api`, no server): `scripts/gen-api.sh`. Needs `pnpm install` at the repo root and Java 11 or newer.

## No Google, and deliberate permissions

The app takes no Google Play Services, Firebase, ML Kit, Play Core, ARCore or other proprietary dependency, so F-Droid can build it.

- `scripts/check-no-google.sh` scans the Gradle build files for the Google Services and Firebase plugins, then resolves every variant's runtime classpath (debug, profile, release) and the pub packages, and fails on any banned name.
- `scripts/test-no-google-probes.sh` adds banned dependencies to a temporary copy of the app and expects the check to catch each one.
- `scripts/check-permissions.sh`, after `flutter build apk --release`, checks that the release APK asks for INTERNET and for no permission outside its allowlist.

CI runs all three.
