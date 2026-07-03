#!/bin/sh
# Sync Ridgits logo from the main Ridgits web project into the iOS asset catalog.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/../Ridgits/ridgits/src/assets/logo.png"
DEST="$ROOT/Ridgits/Assets.xcassets/RidgitsLogo.imageset/logo.png"

if [ ! -f "$SRC" ]; then
  echo "Missing source logo: $SRC" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
cp "$SRC" "$DEST"
echo "Synced logo → $DEST"
