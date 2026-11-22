#!/usr/bin/env python3
"""Generate Textara launcher icons and splash marks from a single brand recipe.

Requires Pillow (`pip install pillow`). Writes:
  - assets/branding/app_icon.png (+ foreground / splash masters)
  - Android mipmaps + adaptive foreground drawables
  - iOS AppIcon + LaunchImage sets
  - macOS AppIcon set

Prefer regenerating via this script before a store build; optional
`flutter_launcher_icons` / `flutter_native_splash` configs in pubspec.yaml
point at the same masters for tooling-driven refreshes.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / 'assets' / 'branding'

PARCHMENT = (245, 240, 232, 255)
INK = (26, 42, 34, 255)
INK_SOFT = (26, 42, 34, 180)
SAGE = (74, 124, 89, 255)
SAGE_SOFT = (74, 124, 89, 40)
PAGE = (255, 252, 247, 255)


def make_icon(size: int) -> Image.Image:
    img = Image.new('RGBA', (size, size), PARCHMENT)
    d = ImageDraw.Draw(img)
    pad = size * 0.08
    d.ellipse([pad, pad, size - pad, size - pad], fill=SAGE_SOFT)
    left = [
        (size * 0.22, size * 0.32),
        (size * 0.50, size * 0.30),
        (size * 0.50, size * 0.72),
        (size * 0.22, size * 0.70),
    ]
    right = [
        (size * 0.50, size * 0.30),
        (size * 0.78, size * 0.32),
        (size * 0.78, size * 0.70),
        (size * 0.50, size * 0.72),
    ]
    d.polygon(left, fill=PAGE, outline=INK)
    d.polygon(right, fill=PAGE, outline=INK)
    d.line(
        [(size * 0.50, size * 0.30), (size * 0.50, size * 0.72)],
        fill=INK,
        width=max(1, size // 64),
    )
    leaf_cx, leaf_cy = size * 0.50, size * 0.48
    leaf_w, leaf_h = size * 0.12, size * 0.18
    d.ellipse(
        [
            leaf_cx - leaf_w / 2,
            leaf_cy - leaf_h / 2,
            leaf_cx + leaf_w / 2,
            leaf_cy + leaf_h / 2,
        ],
        fill=SAGE,
    )
    d.line(
        [(leaf_cx, leaf_cy + leaf_h / 2), (leaf_cx, leaf_cy - leaf_h / 2)],
        fill=PARCHMENT,
        width=max(1, size // 80),
    )
    for i, yf in enumerate((0.40, 0.48, 0.56)):
        y = size * yf
        lw = size * (0.14 - i * 0.015)
        d.line(
            [(size * 0.28, y), (size * 0.28 + lw, y)],
            fill=INK_SOFT,
            width=max(1, size // 128),
        )
        d.line(
            [(size * 0.72 - lw, y), (size * 0.72, y)],
            fill=INK_SOFT,
            width=max(1, size // 128),
        )
    return img


def main() -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    master = make_icon(1024)
    master.save(BRAND / 'app_icon.png')
    master.save(BRAND / 'app_icon_1024.png')

    fg = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    inner = make_icon(768)
    fg.alpha_composite(inner, ((1024 - 768) // 2, (1024 - 768) // 2))
    fg.save(BRAND / 'app_icon_foreground.png')

    splash = Image.new('RGBA', (1152, 1152), PARCHMENT)
    mark = make_icon(512)
    splash.alpha_composite(mark, ((1152 - 512) // 2, (1152 - 512) // 2))
    splash.save(BRAND / 'splash.png')

    for folder, sz in {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }.items():
        out = ROOT / 'android' / 'app' / 'src' / 'main' / 'res' / folder / 'ic_launcher.png'
        make_icon(sz).save(out, 'PNG')

    anydpi = ROOT / 'android' / 'app' / 'src' / 'main' / 'res' / 'mipmap-anydpi-v26'
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / 'ic_launcher.xml').write_text(
        '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
'''
    )

    for folder, sz in [
        ('drawable-mdpi', 108),
        ('drawable-hdpi', 162),
        ('drawable-xhdpi', 216),
        ('drawable-xxhdpi', 324),
        ('drawable-xxxhdpi', 432),
    ]:
        ddir = ROOT / 'android' / 'app' / 'src' / 'main' / 'res' / folder
        ddir.mkdir(parents=True, exist_ok=True)
        canvas = Image.new('RGBA', (sz, sz), (0, 0, 0, 0))
        icon = make_icon(int(sz * 0.72))
        canvas.alpha_composite(icon, ((sz - icon.width) // 2, (sz - icon.height) // 2))
        canvas.save(ddir / 'ic_launcher_foreground.png')

    (
        ROOT / 'android' / 'app' / 'src' / 'main' / 'res' / 'values' / 'colors.xml'
    ).write_text(
        '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#F5F0E8</color>
    <color name="splash_background">#F5F0E8</color>
</resources>
'''
    )

    ios_dir = ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
    for name, sz in {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }.items():
        make_icon(sz).convert('RGB').save(ios_dir / name, 'PNG')

    launch_dir = ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'LaunchImage.imageset'
    for name, sz in [
        ('LaunchImage.png', 168),
        ('LaunchImage@2x.png', 336),
        ('LaunchImage@3x.png', 504),
    ]:
        canvas = Image.new('RGBA', (sz, sz), PARCHMENT)
        mark_img = make_icon(int(sz * 0.42))
        canvas.alpha_composite(
            mark_img, ((sz - mark_img.width) // 2, (sz - mark_img.height) // 2)
        )
        canvas.save(launch_dir / name)

    mac_dir = ROOT / 'macos' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
    for name, sz in {
        'app_icon_16.png': 16,
        'app_icon_32.png': 32,
        'app_icon_64.png': 64,
        'app_icon_128.png': 128,
        'app_icon_256.png': 256,
        'app_icon_512.png': 512,
        'app_icon_1024.png': 1024,
    }.items():
        make_icon(sz).save(mac_dir / name, 'PNG')

    print(f'Generated brand assets under {BRAND}')


if __name__ == '__main__':
    main()
