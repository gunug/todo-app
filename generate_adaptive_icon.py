"""
TodoLift adaptive launcher icon generator.

Builds Android adaptive-icon layers DIRECTLY from the design PNG
(png/20260603_140823_todolift_icon_v4.png) so that the icon rendered on
Android 8.0+ (which uses the adaptive icon, not the mipmap PNGs) matches v4.

- Foreground layer = the white checklist glyph extracted from v4 (white on transparent),
  kept at v4's relative scale so it sits inside the adaptive safe zone.
- Background layer = v4's indigo->purple gradient, full-bleed (so the launcher mask
  shows the gradient edge-to-edge, with no dark corners).

The flat mipmap PNGs (ic_launcher.png / ic_launcher_round.png) are left as-is — they
are already exact resizes of v4 and serve Android < 8.0.
"""

import os
import numpy as np
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(BASE, "..", "png", "20260603_140823_todolift_icon_v4.png"))
RES = os.path.join(BASE, "android", "app", "src", "main", "res")

# Adaptive icon layers are 108dp; per-density pixel sizes:
ADAPTIVE_SIZES = {
    "mipmap-mdpi":    108,
    "mipmap-hdpi":    162,
    "mipmap-xhdpi":   216,
    "mipmap-xxhdpi":  324,
    "mipmap-xxxhdpi": 432,
}


def load_v4():
    return Image.open(SRC).convert("RGBA")


def extract_white_glyph(v4):
    """Return an RGBA image: white where v4 is white (the checklist), transparent elsewhere.

    Whiteness is driven by the per-pixel minimum channel: the gradient keeps at least one
    channel low (R/G are low even where blue is high), while the white strokes are high in
    all channels. Anti-aliasing is preserved via a smooth ramp.
    """
    rgb = np.asarray(v4)[:, :, :3].astype(np.float32)
    minc = rgb.min(axis=2)
    lo, hi = 140.0, 235.0
    alpha = np.clip((minc - lo) / (hi - lo), 0.0, 1.0)
    out = np.zeros(rgb.shape[:2] + (4,), dtype=np.uint8)
    out[:, :, 0] = 255
    out[:, :, 1] = 255
    out[:, :, 2] = 255
    out[:, :, 3] = (alpha * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def fit_gradient_endpoints(v4):
    """Sample v4 along the TL->BR diagonal (avoiding the central glyph band) and linearly
    fit each RGB channel against the adaptive-gradient parameter t=(x+y)/(2*(N-1)).
    Returns (c0, c1): the extrapolated colors at t=0 (TL corner) and t=1 (BR corner)."""
    arr = np.asarray(v4)[:, :, :3].astype(np.float32)
    n = arr.shape[0]
    ts, cols = [], []
    for p in range(40, n - 40, 6):
        # stay near the diagonal but skip the center where the glyph lives
        if abs(p - n / 2) < n * 0.18:
            continue
        c = arr[p, p]
        if c.min() > 150:  # skip white glyph pixels
            continue
        if c.sum() < 90:   # skip dark rounded-corner background pixels
            continue
        ts.append((p + p) / (2 * (n - 1)))
        cols.append(c)
    ts = np.asarray(ts)
    cols = np.asarray(cols)
    c0 = np.zeros(3)
    c1 = np.zeros(3)
    for ch in range(3):
        m, b = np.polyfit(ts, cols[:, ch], 1)
        c0[ch] = b
        c1[ch] = m + b
    c0 = np.clip(c0, 0, 255)
    c1 = np.clip(c1, 0, 255)
    return c0, c1


def make_gradient(size, c0, c1):
    """Full-bleed diagonal (135deg-ish, TL->BR) gradient image of given size."""
    idx = np.add.outer(np.arange(size), np.arange(size)).astype(np.float32)
    t = idx / (2 * (size - 1))
    img = np.zeros((size, size, 4), dtype=np.uint8)
    for ch in range(3):
        img[:, :, ch] = (c0[ch] + (c1[ch] - c0[ch]) * t).astype(np.uint8)
    img[:, :, 3] = 255
    return Image.fromarray(img, "RGBA")


def main():
    v4 = load_v4()
    glyph = extract_white_glyph(v4)
    c0, c1 = fit_gradient_endpoints(v4)
    print(f"gradient endpoints: TL={c0.astype(int).tolist()}  BR={c1.astype(int).tolist()}")

    for folder, px in ADAPTIVE_SIZES.items():
        out_dir = os.path.join(RES, folder)
        os.makedirs(out_dir, exist_ok=True)

        bg = make_gradient(px, c0, c1)
        bg.save(os.path.join(out_dir, "ic_launcher_background.png"))

        fg = glyph.resize((px, px), Image.LANCZOS)
        fg.save(os.path.join(out_dir, "ic_launcher_foreground.png"))
        print(f"  {folder}: {px}x{px} background + foreground saved")

    print("Done. Point mipmap-anydpi-v26 XMLs at @mipmap/ic_launcher_{background,foreground}.")


if __name__ == "__main__":
    main()
