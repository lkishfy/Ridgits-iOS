#!/bin/sh
# Generate iPhone app icon sizes — flat black grid on white (matches Ridgits brand, no gradients).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Ridgits/Assets.xcassets/AppIcon.appiconset"

python3 << PY
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT_DIR = Path("$OUT")
OUT_DIR.mkdir(parents=True, exist_ok=True)

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)

SQUARES = [
    (0, 0, -11),
    (0, 1, 0),
    (0, 2, 11),
    (1, 0, 0),
    (1, 1, 0),
    (1, 2, 0),
    (2, 0, 11),
    (2, 1, 0),
    (2, 2, -11),
]

# Tighter grid — matches brand logo spacing.
GRID_INSET_RATIO = 0.075
GAP_RATIO = 0.038
CORNER_RADIUS_RATIO = 0.24


def flatten_icon(img: Image.Image) -> Image.Image:
    """Force pure black/white — removes anti-aliased gray fringes from rotation and rounded rects."""
    pixels = img.load()
    width, height = img.size
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            pixels[x, y] = BLACK if (r + g + b) < 720 else WHITE
    return img


def paste_rotated_square(canvas, center_x, center_y, cell, radius, rotation_deg, clip_rect):
    """Paste a rotated square clipped to its grid cell — hard black/white only."""
    pad = max(2, int(math.ceil(cell * 0.55)))
    layer_size = int(math.ceil(cell + pad * 2))
    layer = Image.new("RGB", (layer_size, layer_size), WHITE)
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(
        (pad, pad, pad + cell, pad + cell),
        radius=radius,
        fill=BLACK,
    )
    layer = layer.rotate(rotation_deg, resample=Image.Resampling.NEAREST, expand=True)
    layer = flatten_icon(layer)

    paste_x = int(round(center_x - layer.width / 2))
    paste_y = int(round(center_y - layer.height / 2))
    canvas_px = canvas.load()
    layer_px = layer.load()
    width, height = canvas.size
    clip_x0, clip_y0, clip_x1, clip_y1 = clip_rect

    for y in range(layer.height):
        cy = paste_y + y
        if cy < clip_y0 or cy >= clip_y1 or cy < 0 or cy >= height:
            continue
        for x in range(layer.width):
            if layer_px[x, y] == BLACK:
                cx = paste_x + x
                if clip_x0 <= cx < clip_x1 and 0 <= cx < width:
                    canvas_px[cx, cy] = BLACK


def cell_rect(row, col, inset, cell, gap):
    x0 = inset + col * (cell + gap)
    y0 = inset + row * (cell + gap)
    return (x0, y0, x0 + cell, y0 + cell)


def draw_ridgits_app_icon(size_px: int) -> Image.Image:
    canvas = Image.new("RGB", (size_px, size_px), WHITE)
    draw = ImageDraw.Draw(canvas)

    inset = size_px * GRID_INSET_RATIO
    grid_span = size_px - inset * 2
    gap = grid_span * GAP_RATIO
    cell = (grid_span - gap * 2) / 3
    radius = cell * CORNER_RADIUS_RATIO

    for row, col, rotation in SQUARES:
        center_x = inset + col * (cell + gap) + cell / 2
        center_y = inset + row * (cell + gap) + cell / 2
        clip = cell_rect(row, col, inset, cell, gap)

        if rotation:
            paste_rotated_square(canvas, center_x, center_y, cell, radius, rotation, clip)
        else:
            x0 = center_x - cell / 2
            y0 = center_y - cell / 2
            draw.rounded_rectangle(
                (x0, y0, x0 + cell, y0 + cell),
                radius=radius,
                fill=BLACK,
            )

    return flatten_icon(canvas)


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
    icon = draw_ridgits_app_icon(px)
    icon.save(OUT_DIR / filename, format="PNG", optimize=True)
    images.append({"idiom": idiom, "size": size, "scale": scale, "filename": filename})

(OUT_DIR / "Contents.json").write_text(
    json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n"
)
print(f"Generated {len(images)} app icon sizes in {OUT_DIR}")
PY
