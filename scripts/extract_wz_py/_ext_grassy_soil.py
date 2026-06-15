#!/usr/bin/env python3
"""Extract real grassySoil tile PNGs from Map.wz using wz-python + zlib fallback.

Replaces the placeholder PNGs in client/assets/maps/tiles/grassySoil/ with real
images decoded from Map.wz/Tile/grassySoil.img.

Usage:
  .cache/wz-python/.venv/bin/python3 scripts/extract_wz_py/_ext_grassy_soil.py
"""

from __future__ import annotations

import json
import os
import sys
import zlib
from typing import Tuple

sys.path.insert(
    0,
    os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", ".cache", "wz-python"
    ),
)

from PIL import Image
from wzpy.canvas import _read_canvas_bytes
from wzpy.properties import WzCanvasProperty
from wzpy.wz_file import WzFile

WZ_PATH = "/Users/lijianjun/Downloads/冒险岛079/extracted_client/Map.wz"
OUT_DIR = "client/assets/maps/tiles/grassySoil"

SKIP_OFFSETS = [0, 4, 6, 7, 8, 10, 12, 16, 18, 22, 24, 28, 32]


def canvas_origin(canvas: WzCanvasProperty) -> Tuple[int, int]:
    origin = canvas.get("origin")
    if origin is not None and hasattr(origin, "x"):
        return int(origin.x), int(origin.y)
    return 0, 0


def decode_pixels(raw: bytes) -> bytes | None:
    """Try several strategies to decompress raw canvas payload."""
    for skip in SKIP_OFFSETS:
        if skip >= len(raw):
            continue
        chunk = raw[skip:]
        try:
            dobj = zlib.decompressobj()
            out = dobj.decompress(chunk)
            if len(out) >= 64:
                return out
        except Exception:
            pass
        try:
            out = zlib.decompress(chunk, -15)
            if len(out) >= 64:
                return out
        except Exception:
            pass
    return None


def try_decode_to_image(pixels: bytes, w: int, h: int) -> Image.Image | None:
    """Try decoding raw pixel bytes into image using several WZ pixel formats."""
    # Try BGRA8888 (format 2)
    if len(pixels) >= w * h * 4:
        try:
            return Image.frombytes("RGBA", (w, h), pixels[: w * h * 4], "raw", "BGRA")
        except Exception:
            pass
    # Try ARGB4444 (format 1): 2 bytes per pixel -> expand to RGBA
    if len(pixels) >= w * h * 2:
        try:
            arr = bytearray(w * h * 4)
            for i in range(w * h):
                lo = pixels[i * 2]
                hi = pixels[i * 2 + 1]
                b = (lo & 0x0F) | ((lo & 0x0F) << 4)
                g = (lo & 0xF0) | ((lo & 0xF0) >> 4)
                r = (hi & 0x0F) | ((hi & 0x0F) << 4)
                a = (hi & 0xF0) | ((hi & 0xF0) >> 4)
                arr[i * 4 + 0] = r
                arr[i * 4 + 1] = g
                arr[i * 4 + 2] = b
                arr[i * 4 + 3] = a
            return Image.frombytes("RGBA", (w, h), bytes(arr))
        except Exception:
            pass
    # Try ARGB1555 (format 257): 2 bytes per pixel
    if len(pixels) >= w * h * 2:
        try:
            arr = bytearray(w * h * 4)
            for i in range(w * h):
                v = pixels[i * 2] | (pixels[i * 2 + 1] << 8)
                a = 0xFF if v & 0x8000 else 0x00
                r = ((v >> 10) & 0x1F) * 8
                g = ((v >> 5) & 0x1F) * 8
                b = (v & 0x1F) * 8
                arr[i * 4 : i * 4 + 4] = bytes([r, g, b, a])
            return Image.frombytes("RGBA", (w, h), bytes(arr))
        except Exception:
            pass
    # Try downsampled 4x4 BGRA8888 (format 3)
    small_w = (w + 3) // 4
    small_h = (h + 3) // 4
    if len(pixels) >= small_w * small_h * 4:
        try:
            small = Image.frombytes(
                "RGBA", (small_w, small_h), pixels[: small_w * small_h * 4], "raw", "BGRA"
            )
            return small.resize((w, h), Image.NEAREST)
        except Exception:
            pass
    # Try RGB565 (format 513)
    if len(pixels) >= w * h * 2:
        try:
            arr = bytearray(w * h * 4)
            for i in range(w * h):
                v = pixels[i * 2] | (pixels[i * 2 + 1] << 8)
                r = ((v >> 11) & 0x1F) * 8
                g = ((v >> 5) & 0x3F) * 4
                b = (v & 0x1F) * 8
                arr[i * 4 : i * 4 + 4] = bytes([r, g, b, 0xFF])
            return Image.frombytes("RGBA", (w, h), bytes(arr))
        except Exception:
            pass
    return None


def enumerate_dims(pixels: bytes, canvas_w: int, canvas_h: int):
    """Yield candidate (w, h) pairs from pixel byte length and canvas metadata."""
    if canvas_w > 0 and canvas_h > 0:
        yield canvas_w, canvas_h
    expected4 = len(pixels) // 4
    expected2 = len(pixels) // 2
    # Extended height list (includes common Maple tile heights plus nearby
    # values to catch edU/enV/enH style tiles where width/height metadata
    # is unreliable)
    common_heights = (
        17, 19, 22, 25, 26, 27, 37, 38, 50, 55, 60, 64, 76, 77, 85, 95, 100,
        110, 128, 141, 150, 190, 200, 209, 220, 400, 500, 600,
    )
    for guess_h in common_heights:
        if expected4 % guess_h == 0 and expected4 // guess_h > 0:
            yield expected4 // guess_h, guess_h
        if expected2 % guess_h == 0 and expected2 // guess_h > 0:
            yield expected2 // guess_h, guess_h
    # Also try corresponding widths as heights (swapped)
    for guess_w in common_heights:
        if expected4 % guess_w == 0 and expected4 // guess_w > 0:
            yield guess_w, expected4 // guess_w
        if expected2 % guess_w == 0 and expected2 // guess_w > 0:
            yield guess_w, expected2 // guess_w
    if canvas_h > 0:
        if expected4 % canvas_h == 0 and expected4 // canvas_h > 0:
            yield expected4 // canvas_h, canvas_h
        if expected2 % canvas_h == 0 and expected2 // canvas_h > 0:
            yield expected2 // canvas_h, canvas_h
    if canvas_w > 0:
        if expected4 % canvas_w == 0 and expected4 // canvas_w > 0:
            yield canvas_w, expected4 // canvas_w
        if expected2 % canvas_w == 0 and expected2 // canvas_w > 0:
            yield canvas_w, expected2 // canvas_w


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    wf = WzFile.open(WZ_PATH, region="EMS", version=79)
    node = wf.root.get("Tile").get("grassySoil.img")
    if node is None:
        print("ERROR: grassySoil.img not found")
        return 1
    node.parse()

    total = ok = 0
    for group in node.children():
        u = group.name
        if u == "info":
            continue
        for canvas in group.children():
            total += 1
            no = canvas.name
            try:
                raw = _read_canvas_bytes(canvas)
            except Exception as exc:
                print(f"  ✗ {u}/{no}: read error {exc}")
                continue
            pixels = decode_pixels(raw)
            if pixels is None:
                print(f"  ✗ {u}/{no}: decompress failed (len={len(raw)})")
                continue
            img = None
            tried_dims: set[Tuple[int, int]] = set()
            for dims in enumerate_dims(pixels, canvas.width, canvas.height):
                if dims in tried_dims:
                    continue
                tried_dims.add(dims)
                w, h = dims
                if w <= 0 or h <= 0 or w > 1024 or h > 1024:
                    continue
                img = try_decode_to_image(pixels, w, h)
                if img is not None:
                    break
            if img is None:
                print(
                    f"  ✗ {u}/{no}: image decode failed "
                    f"(canvas {canvas.width}x{canvas.height}, pixels {len(pixels)})"
                )
                continue
            w, h = img.size
            path = os.path.join(OUT_DIR, f"{u}_{no}.png")
            img.save(path)
            ox, oy = canvas_origin(canvas)
            with open(path + ".json", "w", encoding="utf-8") as f:
                json.dump({"ox": ox, "oy": oy, "w": w, "h": h}, f)
            print(f"  ✓ {u}/{no}: {w}x{h} ({len(pixels)} bytes)")
            ok += 1

    print(f"--- summary {ok}/{total} ---")
    return 0 if ok > 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
