#!/bin/sh
# Sync Ridgits landing hero images from the web project into the iOS asset catalog.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/Ridgits/Assets.xcassets"
WEB="$ROOT/../Ridgits/ridgits/src/assets"

copy_hero() {
  num="$1"
  src_suffix="$2"
  src="$WEB/1024${src_suffix}-optimized.jpg"
  dest="$ASSETS/HeroStack${num}.imageset/hero.jpg"
  if [ ! -f "$src" ]; then
    echo "Missing source image: $src" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "Synced HeroStack${num} → $dest"
}

copy_hero 1 ""
copy_hero 2 "-2"
copy_hero 3 "-3"
copy_hero 4 "-4"
