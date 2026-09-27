#!/usr/bin/env python3
"""Scales the rendered icon layers into Android launcher icons.

Run `flutter test tool/icon/render_icon_test.dart` first, then this script.
Requires Pillow.
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(os.path.dirname(__file__), "out")
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}


def rounded(img, radius_ratio=0.22):
    size = img.size[0]
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * radius_ratio), fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def circle(img):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse([0, 0, img.size[0] - 1, img.size[1] - 1], fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


full = Image.open(os.path.join(OUT, "full.png")).convert("RGBA")
fg = Image.open(os.path.join(OUT, "foreground.png")).convert("RGBA")
bg = Image.open(os.path.join(OUT, "background.png")).convert("RGBA")
splash = Image.open(os.path.join(OUT, "splash.png")).convert("RGBA")

for density, px in LEGACY.items():
    d = os.path.join(RES, f"mipmap-{density}")
    os.makedirs(d, exist_ok=True)
    rounded(full).resize((px, px), Image.LANCZOS).save(os.path.join(d, "ic_launcher.png"))
    circle(full).resize((px, px), Image.LANCZOS).save(os.path.join(d, "ic_launcher_round.png"))
for density, px in ADAPTIVE.items():
    d = os.path.join(RES, f"mipmap-{density}")
    fg.resize((px, px), Image.LANCZOS).save(os.path.join(d, "ic_launcher_foreground.png"))
    bg.resize((px, px), Image.LANCZOS).save(os.path.join(d, "ic_launcher_background.png"))

anydpi = os.path.join(RES, "mipmap-anydpi-v26")
os.makedirs(anydpi, exist_ok=True)
xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""
for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
    with open(os.path.join(anydpi, name), "w") as f:
        f.write(xml)

# Launch screen logo (shown at 96dp).
d = os.path.join(RES, "drawable-xxxhdpi")
os.makedirs(d, exist_ok=True)
splash.resize((384, 384), Image.LANCZOS).save(os.path.join(d, "splash_logo.png"))

# Store listing icon (512 x 512, no transparency).
store = os.path.join(ROOT, "store")
os.makedirs(store, exist_ok=True)
full.convert("RGB").resize((512, 512), Image.LANCZOS).save(os.path.join(store, "play_store_icon_512.png"))

# Web favicon / PWA icons.
web = os.path.join(ROOT, "web")
rounded(full).resize((32, 32), Image.LANCZOS).save(os.path.join(web, "favicon.png"))
for px in (192, 512):
    rounded(full).resize((px, px), Image.LANCZOS).save(os.path.join(web, "icons", f"Icon-{px}.png"))
    full.resize((px, px), Image.LANCZOS).save(os.path.join(web, "icons", f"Icon-maskable-{px}.png"))
print("launcher icons written")
