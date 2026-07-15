#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODS_DIR="/Users/mdite/Library/Application Support/factorio/mods"
MOD_NAME="suspension-coffin"
MOD_VERSION="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT_DIR/info.json")"

"$ROOT_DIR/scripts/package.sh"

mkdir -p "$MODS_DIR"
rm -f "$MODS_DIR/${MOD_NAME}"_*.zip
cp "$ROOT_DIR/dist/${MOD_NAME}_${MOD_VERSION}.zip" "$MODS_DIR/"

echo "Deployed:"
echo "  $MODS_DIR/${MOD_NAME}_${MOD_VERSION}.zip"
