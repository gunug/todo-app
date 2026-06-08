"""
TodoLift app icon generator.
Creates a 1024x1024 icon with indigo→purple gradient and white checklist symbol,
then resizes to Android mipmap sizes (square + round).

DEPRECATED — do not run. The launcher icon is now sourced from the design PNG
png/20260603_140823_todolift_icon_v4.png. The flat mipmaps are exact resizes of
v4, and the adaptive-icon layers (Android 8.0+) are generated from v4 by
generate_adaptive_icon.py. Running this script would overwrite both with the old
programmatically-drawn design and re-create the now-removed adaptive vector
drawables — i.e. it would revert the icon. Use generate_adaptive_icon.py instead.
"""

import math
import os
from PIL import Image, ImageDraw

BASE = r"c:\Users\gunug\OneDrive - OneTheLab\00_project\todo-app"
RES  = os.path.join(BASE, "android", "app", "src", "main", "res")

SIZES = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}

INDIGO = (63, 81, 181)    # #3F51B5
PURPLE = (124, 77, 255)   # #7C4DFF
WHITE  = (255, 255, 255)
SIZE   = 1024


def make_gradient(size):
    img = Image.new("RGBA", (size, size))
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            r = int(INDIGO[0] + (PURPLE[0] - INDIGO[0]) * t)
            g = int(INDIGO[1] + (PURPLE[1] - INDIGO[1]) * t)
            b = int(INDIGO[2] + (PURPLE[2] - INDIGO[2]) * t)
            pixels[x, y] = (r, g, b, 255)
    return img


def draw_checklist(draw, cx, cy, icon_size):
    """Draw a minimal white checklist: rounded rect + 3 rows of check + line."""
    s = icon_size
    # Rounded rectangle outline
    rect_w = int(s * 0.55)
    rect_h = int(s * 0.65)
    rx = cx - rect_w // 2
    ry = cy - rect_h // 2
    radius = int(s * 0.07)
    lw = max(3, int(s * 0.04))

    draw.rounded_rectangle(
        [rx, ry, rx + rect_w, ry + rect_h],
        radius=radius,
        outline=WHITE,
        width=lw,
    )

    # 3 rows
    rows = 3
    row_gap = rect_h // (rows + 1)
    check_size = int(s * 0.065)
    line_len = int(rect_w * 0.45)

    for i in range(rows):
        row_y = ry + row_gap * (i + 1)
        # Checkmark (tick) at left inside rect
        tick_x = rx + int(rect_w * 0.14)
        # Simple tick: two line segments
        t1x, t1y = tick_x,                  row_y + check_size // 3
        t2x, t2y = tick_x + check_size // 2, row_y + check_size
        t3x, t3y = tick_x + check_size,     row_y - check_size // 3
        draw.line([(t1x, t1y), (t2x, t2y)], fill=WHITE, width=max(2, lw - 1))
        draw.line([(t2x, t2y), (t3x, t3y)], fill=WHITE, width=max(2, lw - 1))
        # Horizontal text line at right
        lx = rx + int(rect_w * 0.38)
        draw.line(
            [(lx, row_y), (lx + line_len, row_y)],
            fill=WHITE,
            width=max(2, lw - 1),
        )


def make_icon(size=SIZE):
    img = make_gradient(size)
    draw = ImageDraw.Draw(img)
    draw_checklist(draw, size // 2, size // 2, size)
    return img


def apply_round_mask(img):
    size = img.size[0]
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse([0, 0, size - 1, size - 1], fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def save_all(base_icon):
    for folder, px in SIZES.items():
        out_dir = os.path.join(RES, folder)
        os.makedirs(out_dir, exist_ok=True)

        square = base_icon.resize((px, px), Image.LANCZOS)
        square.save(os.path.join(out_dir, "ic_launcher.png"))

        round_img = apply_round_mask(square)
        round_img.save(os.path.join(out_dir, "ic_launcher_round.png"))

        print(f"  {folder}: {px}x{px} saved")


def make_adaptive_xml():
    """Write mipmap-anydpi-v26 adaptive icon XML."""
    anydpi_dir = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi_dir, exist_ok=True)

    ic_launcher_xml = """\
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""
    with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w") as f:
        f.write(ic_launcher_xml)
    with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w") as f:
        f.write(ic_launcher_xml)

    # Write background and foreground drawables
    drawable_dir = os.path.join(RES, "drawable")
    os.makedirs(drawable_dir, exist_ok=True)

    bg_xml = """\
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:startColor="#3F51B5"
        android:endColor="#7C4DFF"
        android:angle="135"/>
</shape>
"""
    with open(os.path.join(drawable_dir, "ic_launcher_background.xml"), "w") as f:
        f.write(bg_xml)

    # Foreground: white checklist as vector drawable
    fg_xml = """\
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">

  <!-- Checklist rounded rectangle -->
  <path
      android:pathData="M36,22 L72,22 Q76,22 76,26 L76,82 Q76,86 72,86 L36,86 Q32,86 32,82 L32,26 Q32,22 36,22 Z"
      android:strokeColor="#FFFFFF"
      android:strokeWidth="3"
      android:fillColor="#00000000"/>

  <!-- Row 1 check + line -->
  <path
      android:pathData="M40,39 L43,44 L49,34"
      android:strokeColor="#FFFFFF"
      android:strokeWidth="2.5"
      android:fillColor="#00000000"
      android:strokeLineCap="round"
      android:strokeLineJoin="round"/>
  <path
      android:pathData="M53,39 L70,39"
      android:strokeColor="#FFFFFF"
      android:strokeWidth="2.5"
      android:fillColor="#00000000"
      android:strokeLineCap="round"/>

  <!-- Row 2 check + line -->
  <path
      android:pathData="M40,54 L43,59 L49,49"
      android:strokeColor="#FFFFFF"
      android:strokeWidth="2.5"
      android:fillColor="#00000000"
      android:strokeLineCap="round"
      android:strokeLineJoin="round"/>
  <path
      android:pathData="M53,54 L70,54"
      android:strokeColor="#FFFFFF"
      android:strokeWidth="2.5"
      android:fillColor="#00000000"
      android:strokeLineCap="round"/>

  <!-- Row 3 check (empty) + line -->
  <path
      android:pathData="M40,69 L43,74 L49,64"
      android:strokeColor="#FFFFFF"
      android:strokeWidth="2.5"
      android:fillColor="#00000000"
      android:strokeLineCap="round"
      android:strokeLineJoin="round"/>
  <path
      android:pathData="M53,69 L70,69"
      android:strokeColor="#FFFFFF"
      android:strokeWidth="2.5"
      android:fillColor="#00000000"
      android:strokeLineCap="round"/>
</vector>
"""
    with open(os.path.join(drawable_dir, "ic_launcher_foreground.xml"), "w") as f:
        f.write(fg_xml)

    print("  mipmap-anydpi-v26: adaptive icon XMLs saved")
    print("  drawable: ic_launcher_background.xml + ic_launcher_foreground.xml saved")


if __name__ == "__main__":
    print("Generating TodoLift icon...")
    icon = make_icon()

    # Save full-size reference
    ref_path = os.path.join(BASE, "todolift_icon_1024.png")
    icon.save(ref_path)
    print(f"Reference icon: {ref_path}")

    print("Saving mipmap sizes...")
    save_all(icon)

    print("Writing adaptive icon XMLs...")
    make_adaptive_xml()

    print("Done.")
