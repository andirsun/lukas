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

## No Google

The app takes no Google Play Services, Firebase, ML Kit or Play Core dependency, so F-Droid can build it. `scripts/check-no-google.sh` resolves the release Gradle classpath and the pub packages and fails on any of them; CI runs it.
