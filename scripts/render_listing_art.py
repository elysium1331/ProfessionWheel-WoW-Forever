#!/usr/bin/env python3
"""Render the CurseForge logo and banner from the addon's own wheel art, so the
listing images match the in-game wheel. Uses the same proportions as Wheel.lua.

  python scripts/render_listing_art.py

Inputs: art/wheel/*.png and art/icons/*.png (from build_wheel_art.py) and
art/curseforge/raw/banner.png (background scene). Outputs: art/curseforge/logo.png,
art/curseforge/banner.png. Requires Pillow.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
WHEEL = ROOT / "art" / "wheel"
ICONS = ROOT / "art" / "icons"
CF = ROOT / "art" / "curseforge"

LOGO_ICONS = ["tailoring", "blacksmithing", "alchemy", "fishing", "mining"]


def tex(path):
    return Image.open(path).convert("RGBA")


def render_wheel(size, keys, selected=None):
    """Draw the wheel like View:Layout / View:Refresh in Wheel.lua."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    S = size

    def put(img, d, cx, cy, rot=0):
        im = img.resize((max(1, int(d)), max(1, int(d))), Image.LANCZOS)
        if rot:
            im = im.rotate(rot, resample=Image.BICUBIC)
        canvas.alpha_composite(im, (int(S / 2 + cx - d / 2), int(S / 2 - cy - d / 2)))

    put(tex(WHEEL / "disc.png"), S, 0, 0)
    n = len(keys)
    slot = round(S * 0.27)
    r = S / 2 - slot / 2 - S * 0.06
    sector = 360 / n
    for i in range(n):
        a = i * sector
        put(tex(WHEEL / "spoke.png"), r / 0.9, (r / 2) * math.sin(math.radians(a)), (r / 2) * math.cos(math.radians(a)), 90 - a)
        if n > 1:
            sa = math.radians((i + 0.5) * sector)
            sr = r + slot * 0.05
            put(tex(WHEEL / "star.png"), slot * 0.34, sr * math.sin(sa), sr * math.cos(sa))
    hub = S * 0.18
    glow = tex(WHEEL / "hub_glow.png")
    glow.putalpha(glow.getchannel("A").point(lambda v: int(v * (0.75 if selected is not None else 0.45))))
    put(glow, hub * 1.8, 0, 0)
    put(ImageEnhance.Brightness(tex(WHEEL / "hub.png")).enhance(0.8), hub, 0, 0)
    for i, key in enumerate(keys):
        a = math.radians(i * sector)
        x, y = r * math.sin(a), r * math.cos(a)
        if i == selected:
            put(tex(WHEEL / "slot_glow.png"), slot * 1.5, x, y)
        well = Image.new("RGBA", (int(slot * 0.88),) * 2, (0, 0, 0, 0))
        ImageDraw.Draw(well).ellipse((0, 0, well.size[0] - 1, well.size[1] - 1), fill=(18, 15, 13, 255))
        put(well, slot * 0.88, x, y)
        put(tex(ICONS / f"{key}.png"), slot * 0.84, x, y)
        put(tex(WHEEL / "slot.png"), slot, x, y)
    return canvas


def vignette(size, inner=(58, 34, 20), outer=(12, 8, 6)):
    img = Image.new("RGB", (size, size))
    px = img.load()
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            d = min(1.0, math.hypot(x - c, y - c) / (size * 0.72))
            px[x, y] = tuple(int(inner[k] + (outer[k] - inner[k]) * d) for k in range(3))
    return img.convert("RGBA")


def main():
    # Logo: 1024 square, wheel at 92%, top slot selected.
    logo = vignette(1024)
    wheel = render_wheel(940, LOGO_ICONS, selected=0)
    logo.alpha_composite(wheel, (42, 42))
    logo.convert("RGB").save(CF / "logo.png")
    print("art/curseforge/logo.png 1024x1024")

    # Banner: the generated workshop scene, with the real wheel over the left third.
    scene = tex(CF / "raw" / "banner.png").resize((1920, 1080), Image.LANCZOS)
    scene = ImageEnhance.Brightness(scene.filter(ImageFilter.GaussianBlur(3))).enhance(0.8)
    shadow = Image.new("RGBA", (980, 980), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((20, 20, 960, 960), fill=(0, 0, 0, 200))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    scene.alpha_composite(shadow, (-10, 60))
    scene.alpha_composite(render_wheel(920, LOGO_ICONS, selected=0), (20, 80))
    scene.convert("RGB").save(CF / "banner.png")
    print("art/curseforge/banner.png 1920x1080")


if __name__ == "__main__":
    main()
