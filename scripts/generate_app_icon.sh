#!/bin/sh
# Generate all required iPhone App Store icon sizes from the Ridgits web logo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/../Ridgits/ridgits/src/assets/logo.png"
OUT="$ROOT/Ridgits/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SRC" ]; then
  echo "Missing source logo: $SRC" >&2
  exit 1
fi

python3 << PY
import json
from pathlib import Path
from PIL import Image

src = Path("$SRC")
out_dir = Path("$OUT")

img = Image.open(src).convert("RGBA")
w, h = img.size
side = min(w, h)
left = (w - side) // 2
top = (h - side) // 2
img = img.crop((left, top, left + side, top + side))

entries = [
    ("iphone", "20x20", "2x", 40, "Icon-20@2x.png"),
    ("iphone", "20x20", "3x", 60, "Icon-20@3x.png"),
    ("iphone", "29x29", "2x", 58, "Icon-29@2x.png"),
    ("iphone", "29x29", "3x", 87, "Icon-29@3x.png"),
    ("iphone", "40x40", "2x", 80, "Icon-40@2x.png"),
    ("iphone", "40x40", "3x", 120, "Icon-40@3x.png"),
    ("iphone", "60x60", "2x", 120, "Icon-60@2x.png"),
    ("iphone", "60x60", "3x", 180, "Icon-60@3x.png"),
    ("ios-marketing", "1024x1024", "1x", 1024, "Icon-1024.png"),
]

images = []
for idiom, size, scale, px, filename in entries:
    resized = img.resize((px, px), Image.Resampling.LANCZOS)
    bg = Image.new("RGB", (px, px), (0, 0, 0))
    bg.paste(resized, mask=resized.split()[3])
    bg.save(out_dir / filename, format="PNG", optimize=True)
    images.append({"idiom": idiom, "size": size, "scale": scale, "filename": filename})

(out_dir / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
print(f"Generated {len(images)} app icon sizes in {out_dir}")
PY
