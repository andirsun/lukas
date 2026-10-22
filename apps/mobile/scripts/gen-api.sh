#!/usr/bin/env bash
# Generates the API client in lib/api/gen from the API's OpenAPI document.
#
# The document is built from the API app itself, with no server and no database, the way the web's
# types are (`pnpm --filter @lukas/web api:types --file`). openapi-generator's dart-dio generator
# (version pinned in scripts/openapitools.json) turns it into a Dart package; its lib/ is copied
# into lib/api/gen with `package:lukitas_api/` imports rewritten to `package:lukitas/api/gen/`,
# then build_runner writes the built_value parts and dart format formats the result.
#
# Usage, from anywhere: apps/mobile/scripts/gen-api.sh
# Needs: pnpm install done at the repo root, Java 11 or newer (17 in CI), and Flutter.
# CI runs it and fails when lib/api/gen differs from what is committed.
set -euo pipefail

# The npm wrapper that downloads the pinned generator jar from Maven Central.
GENERATOR_CLI="@openapitools/openapi-generator-cli@2.41.0"

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$MOBILE/../.." && pwd)"
OUT="$MOBILE/lib/api/gen"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> OpenAPI document (from apps/api, no server)"
(cd "$ROOT" && pnpm --silent --filter @lukas/web api:types --file --document "$WORK/openapi.json")

echo "==> openapi-generator dart-dio"
(cd "$WORK" && npx --yes "$GENERATOR_CLI" --openapitools "$MOBILE/scripts/openapitools.json" \
  generate \
  --generator-name dart-dio \
  --input-spec "$WORK/openapi.json" \
  --output "$WORK/client" \
  --global-property apiTests=false,modelTests=false,apiDocs=false,modelDocs=false \
  --additional-properties pubName=lukitas_api,pubLibrary=lukitas_api \
  >"$WORK/generator.log" 2>&1) || {
  cat "$WORK/generator.log"
  exit 1
}

echo "==> lib/api/gen"
rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$WORK/client/lib/." "$OUT/"
find "$OUT" -name '*.dart' -exec perl -pi -e 's#package:lukitas_api/#package:lukitas/api/gen/#g' {} +

cd "$MOBILE"
echo "==> build_runner (built_value parts)"
flutter pub get --enforce-lockfile >/dev/null
dart run build_runner build --delete-conflicting-outputs >"$WORK/build_runner.log" 2>&1 || {
  cat "$WORK/build_runner.log"
  exit 1
}
dart format lib/api/gen >/dev/null
echo "Wrote $OUT"
