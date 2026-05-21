#!/usr/bin/env bash
# Build + install + launch jr_sport on a booted iOS Simulator.
# Usage: ./run.sh [simulator-name]   (default: "iPhone 17 Pro")
set -euo pipefail
cd "$(dirname "$0")"

TARGET="jr_sport"
BUNDLE_ID="com.jrsport.app"
SIM_NAME="${1:-iPhone 17 Pro}"
BUILD_DIR="$PWD/build/Products"
APP_PATH="${BUILD_DIR}/Debug-iphonesimulator/${TARGET}.app"
LOG=/tmp/jr_sport_build.log

# ── Colors ────────────────────────────────────────────────────────────
b() { printf "\033[1m%s\033[0m\n" "$*"; }
g() { printf "\033[2m  %s\033[0m\n" "$*"; }

# ── Regenerate xcodeproj if project.yml changed ──────────────────────
if [ project.yml -nt jr_sport.xcodeproj ] && command -v xcodegen >/dev/null; then
  b "▸ project.yml changed — regenerating xcodeproj"
  xcodegen generate >/dev/null
fi

# ── Boot simulator ────────────────────────────────────────────────────
b "▸ Booting simulator: ${SIM_NAME}"
xcrun simctl boot "${SIM_NAME}" 2>/dev/null || g "(already booted)"
open -a Simulator

# ── Build ─────────────────────────────────────────────────────────────
# NOTE: this Xcode install has two quirks worked around here:
#   1. Simulator runtime mismatch — iOS 26.4 simulator runtime (build
#      23E244) is older than the SDK (23E252), so actool refuses to
#      thin the asset catalog. Workaround: disable the AppIcon name
#      so the thinned compile step is skipped.
#   2. Scheme destination resolution is flaky — xcodebuild reports
#      "Found no destinations" intermittently. Workaround: invoke
#      via `-target` (not `-scheme`) with SYMROOT — bypasses the
#      destination resolver entirely.
# Both can be undone by reinstalling matching simulator components
# via Xcode → Settings → Components.
b "▸ Building ${TARGET}"
if xcodebuild \
    -project "${TARGET}.xcodeproj" \
    -target "${TARGET}" \
    -sdk iphonesimulator \
    -configuration Debug \
    SYMROOT="${BUILD_DIR}" \
    SDKROOT=iphonesimulator \
    CODE_SIGNING_ALLOWED=NO \
    ASSETCATALOG_COMPILER_APPICON_NAME='' \
    build > "${LOG}" 2>&1; then
  g "build ok"
else
  printf "\033[31m  build failed — last 40 lines of %s:\033[0m\n" "${LOG}"
  tail -40 "${LOG}"
  exit 1
fi

# ── Install + launch ──────────────────────────────────────────────────
b "▸ Installing"
xcrun simctl install booted "${APP_PATH}"

b "▸ Launching ${BUNDLE_ID}"
xcrun simctl terminate booted "${BUNDLE_ID}" 2>/dev/null || true
xcrun simctl launch booted "${BUNDLE_ID}" >/dev/null

b "▸ Ready"
g "Logs:  xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS \"jrsport\"'"
g "Shot:  xcrun simctl io booted screenshot /tmp/jr_sport.png"
