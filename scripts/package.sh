#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/.build"
MOD_NAME="suspension-coffin"
MOD_VERSION="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT_DIR/info.json")"

package_variant() {
  local mod_version="$1"
  local package_root="$BUILD_DIR/${MOD_NAME}_${mod_version}"
  local zip_path="$DIST_DIR/${MOD_NAME}_${mod_version}.zip"

  rm -rf "$package_root"
  mkdir -p "$package_root"

  rsync -a \
    --exclude ".build" \
    --exclude ".DS_Store" \
    --exclude ".git" \
    --exclude "dist" \
    "$ROOT_DIR/" "$package_root/"

  python3 - "$package_root/info.json" "$mod_version" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
mod_version = sys.argv[2]

data = json.loads(path.read_text())
data["version"] = mod_version

path.write_text(json.dumps(data, indent=2) + "\n")
PY

  rm -f "$zip_path"
  (
    cd "$BUILD_DIR"
    zip -qr "$zip_path" "${MOD_NAME}_${mod_version}"
  )
}

rm -rf "$BUILD_DIR"
mkdir -p "$DIST_DIR" "$BUILD_DIR"
rm -f "$DIST_DIR/${MOD_NAME}"_*.zip

package_variant "$MOD_VERSION"

rm -rf "$BUILD_DIR"

echo "Created:"
echo "  $DIST_DIR/${MOD_NAME}_${MOD_VERSION}.zip"
