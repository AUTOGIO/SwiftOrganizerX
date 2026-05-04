#!/usr/bin/env bash
# launch.sh — build SwiftOrganizerX (debug) and open it in one step.
#
# Usage:
#   bash scripts/launch.sh          # debug build (fast)
#   bash scripts/launch.sh release  # release build (optimised)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SwiftOrganizerX"
CONFIG="${1:-debug}"

cd "$ROOT_DIR"

echo "▶ Building ${APP_NAME} (${CONFIG})..."
swift build -c "$CONFIG"

BINARY="$(find "$ROOT_DIR/.build/${CONFIG}" -name "$APP_NAME" -type f | head -n 1)"

if [[ -z "$BINARY" ]]; then
  echo "Build artefact not found in .build/${CONFIG}/." >&2
  exit 1
fi

echo "✅ Build succeeded. Launching ${APP_NAME}..."
exec "$BINARY"
