#!/usr/bin/env python3
"""Build the wheel's runtime textures (Media/Wheel/*.tga) from generated art.

Requires Pillow:  python -m pip install pillow

  python scripts/build_wheel_art.py

Inputs: art/wheel/raw/<piece>.png, painted on a flat magenta (#FF00FF) background.
The magenta is keyed out (with a soft edge and magenta despill), the object is
trimmed and centered on a square canvas, and the result is saved as an
uncompressed 32-bit TGA with a power-of-two size. Two glow textures are generated
procedurally (no source art). Approved PNG previews go to art/wheel/<piece>.png.
"""
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "art" / "wheel" / "raw"
PREVIEW = ROOT / "art" / "wheel"
OUT = ROOT / "Media" / "Wheel"

# piece -> (output size, fraction of the canvas the trimmed object should span)
PIECES = {
    "disc": (512, 1.0),
    "slot": (128, 1.0),
    "hub": (128, 1.0),
    "spoke": (256, None),  # keep the raw framing: the bar must stay centered at 90% width
    "star": (64, 1.0),
}

HARD, SOFT = 60, 140  # color distance from magenta: <= HARD transparent, >= SOFT opaque


def key_magenta(img):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            d = math.sqrt((255 - r) ** 2 + g ** 2 + (255 - b) ** 2)
            if d <= HARD:
                px[x, y] = (0, 0, 0, 0)
                continue
            alpha = 255 if d >= SOFT else int(255 * (d - HARD) / (SOFT - HARD))
            m = min(r, b)
            if m > g and alpha < 255:  # despill the magenta fringe
                excess = m - g
                r, b = r - excess, b - excess
            px[x, y] = (r, g, b, min(a, alpha))
    return img


def square_trim(img, span):
    """Trim to the visible content, then center it on a square canvas."""
    bbox = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if not bbox:
        raise SystemExit("piece is empty after keying")
    content = img.crop(bbox)
    side = max(content.size)
    canvas = int(math.ceil(side / span))
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.alpha_composite(content, ((canvas - content.size[0]) // 2, (canvas - content.size[1]) // 2))
    return out


def ring_glow(size, inner, outer, color):
    """Soft halo: brightest between `inner` and `outer` (fractions of the radius)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c) / (size / 2)
            if d < inner:
                a = max(0.0, 1 - (inner - d) / 0.12)
            elif d <= outer:
                a = 1 - (d - inner) / (outer - inner)
            else:
                a = 0
            px[x, y] = (*color, int(255 * max(0.0, min(1.0, a)) ** 1.6))
    return img


def save(img, name, size):
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    final = img.resize((size, size), Image.LANCZOS)
    final.save(PREVIEW / f"{name}.png")
    final.save(OUT / f"{name}.tga", format="TGA", rle=False)
    print(f"Media/Wheel/{name}.tga  {size}x{size}")


ICON_RAW = ROOT / "art" / "icons" / "raw"
ICON_PREVIEW = ROOT / "art" / "icons"
ICON_OUT = ROOT / "Media" / "Icons"
ICON_KEYS = [
    "alchemy", "blacksmithing", "enchanting", "engineering", "herbalism", "leatherworking",
    "mining", "skinning", "tailoring", "cooking", "firstaid", "fishing", "generic",
]


def fit_icon(img, size, radius_frac=0.42):
    """Center the symbol so every visible pixel lies inside the slot's round well."""
    alpha = img.getchannel("A")
    bbox = alpha.point(lambda a: 255 if a > 24 else 0).getbbox()
    if not bbox:
        raise SystemExit("icon is empty after keying")
    content = img.crop(bbox)
    cw, ch = content.size
    px = content.getchannel("A").load()
    far = 0.0
    for y in range(0, ch, 2):
        for x in range(0, cw, 2):
            if px[x, y] > 24:
                far = max(far, math.hypot(x - cw / 2, y - ch / 2))
    scale = radius_frac * size / far
    small = content.resize((max(1, round(cw * scale)), max(1, round(ch * scale))), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(small, ((size - small.size[0]) // 2, (size - small.size[1]) // 2))
    return out


def build_icons():
    ICON_OUT.mkdir(parents=True, exist_ok=True)
    for key in ICON_KEYS:
        src = ICON_RAW / f"{key}.png"
        if not src.is_file():
            print(f"missing icon art: {src.name}")
            continue
        img = fit_icon(key_magenta(Image.open(src)), 256)
        img.save(ICON_PREVIEW / f"{key}.png")
        img.resize((128, 128), Image.LANCZOS).save(ICON_OUT / f"{key}.tga", format="TGA", rle=False)
        print(f"Media/Icons/{key}.tga  128x128")


def main():
    build_icons()
    for name, (size, span) in PIECES.items():
        img = key_magenta(Image.open(RAW / f"{name}.png"))
        if span is not None:
            img = square_trim(img, span)
        else:
            w, h = img.size
            side = min(w, h)
            img = img.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))
        save(img, name, size)
    # Selected-slot halo and hub glow, generated.
    save(ring_glow(256, 0.62, 1.0, (255, 196, 92)), "slot_glow", 128)
    save(ring_glow(256, 0.30, 1.0, (255, 170, 70)), "hub_glow", 128)


if __name__ == "__main__":
    main()
