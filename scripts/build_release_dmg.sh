#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$BUILD_DIR/DerivedData}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$BUILD_DIR/App.xcarchive}"
STAGING_DIR="${STAGING_DIR:-$BUILD_DIR/dmg-staging}"
OUTPUT_DIR="${OUTPUT_DIR:-$BUILD_DIR/dmg}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-}"
CONFIGURATION="${CONFIGURATION:-Release}"

TAG_NAME="${TAG_NAME:-${GITHUB_REF_NAME:-}}"
TAG_NAME="${TAG_NAME#refs/tags/}"
TAG_NAME="${TAG_NAME:-manual}"

log() {
  echo "[build_release_dmg] $*"
}

find_first_match() {
  local pattern="$1"
  find "$ROOT_DIR" -mindepth 1 -maxdepth 5 -type d -name "$pattern" \
    ! -path "*/.build/*" ! -path "*/DerivedData/*" | head -n 1
}

WORKSPACE_PATH="${XCODE_WORKSPACE_PATH:-}"
PROJECT_PATH="${XCODE_PROJECT_PATH:-}"

if [[ -z "$WORKSPACE_PATH" && -z "$PROJECT_PATH" ]]; then
  WORKSPACE_PATH="$(find_first_match "*.xcworkspace")"
  if [[ -z "$WORKSPACE_PATH" ]]; then
    PROJECT_PATH="$(find_first_match "*.xcodeproj")"
  fi
fi

if [[ -n "$WORKSPACE_PATH" ]]; then
  BUILD_CONTAINER_FLAG=(-workspace "$WORKSPACE_PATH")
  log "Using workspace: $WORKSPACE_PATH"
elif [[ -n "$PROJECT_PATH" ]]; then
  BUILD_CONTAINER_FLAG=(-project "$PROJECT_PATH")
  log "Using project: $PROJECT_PATH"
else
  cat >&2 <<'MSG'
No Xcode workspace/project found.
Set one of:
- XCODE_WORKSPACE_PATH (e.g. MyApp.xcworkspace)
- XCODE_PROJECT_PATH (e.g. MyApp.xcodeproj)
MSG
  exit 1
fi

SCHEME_NAME="${XCODE_SCHEME:-}"
if [[ -z "$SCHEME_NAME" ]]; then
  list_json="$(xcodebuild "${BUILD_CONTAINER_FLAG[@]}" -list -json)"
  SCHEME_NAME="$(python3 -c 'import json,sys; data=json.load(sys.stdin); schemes=data.get("workspace",{}).get("schemes") or data.get("project",{}).get("schemes") or []; print(schemes[0] if schemes else "")' <<<"$list_json")"
fi

if [[ -z "$SCHEME_NAME" ]]; then
  cat >&2 <<'MSG'
Unable to auto-detect a scheme.
Set XCODE_SCHEME to a shared macOS app scheme.
MSG
  exit 1
fi

log "Using scheme: $SCHEME_NAME"

rm -rf "$DERIVED_DATA_PATH" "$ARCHIVE_PATH" "$STAGING_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" "$STAGING_DIR"

ARCHIVE_CMD=(
  xcodebuild
  "${BUILD_CONTAINER_FLAG[@]}"
  -scheme "$SCHEME_NAME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  -archivePath "$ARCHIVE_PATH"
  -destination "generic/platform=macOS"
  archive
)

if [[ -n "$EXPORT_OPTIONS_PLIST" && -f "$EXPORT_OPTIONS_PLIST" ]]; then
  ARCHIVE_CMD+=("-exportOptionsPlist" "$EXPORT_OPTIONS_PLIST")
fi

log "Archiving app..."
"${ARCHIVE_CMD[@]}"

APP_PATH="$(find "$ARCHIVE_PATH/Products/Applications" -maxdepth 1 -type d -name "*.app" | head -n 1)"
if [[ -z "$APP_PATH" ]]; then
  echo "No .app found in archive output at $ARCHIVE_PATH/Products/Applications" >&2
  exit 1
fi

APP_BASENAME="$(basename "$APP_PATH")"
APP_NAME="${APP_BASENAME%.app}"
DMG_PATH="$OUTPUT_DIR/${APP_NAME}-${TAG_NAME}.dmg"

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

log "Creating DMG: $DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

log "Created $DMG_PATH"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "dmg_path=$DMG_PATH"
    echo "dmg_name=$(basename "$DMG_PATH")"
  } >> "$GITHUB_OUTPUT"
fi
