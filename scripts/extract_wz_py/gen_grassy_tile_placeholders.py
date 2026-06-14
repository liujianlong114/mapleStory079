#!/usr/bin/env python3
"""从 ms079 XML 尺寸生成 grassySoil 缺项贴图占位（WZ 部分 tile 无法 decode 时）。"""

from __future__ import annotations

import json
import os
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

XML = os.environ.get(
    "GRASSY_TILE_XML",
    "/Users/lijianjun/GolandProjects/mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/wz/Map.wz/Tile/grassySoil.img.xml",
)
OUT = os.environ.get("OUT", "client/assets/maps/tiles/grassySoil")


def _colors(u: str) -> tuple:
    if u.startswith("enV"):
        return (0x5D, 0x40, 0x37), (0x66, 0xBB, 0x6A)
    if u.startswith("enH") or u == "edU":
        return (0x8D, 0x6E, 0x63), (0x66, 0xBB, 0x6A)
    if u == "edD":
        return (0x4E, 0x34, 0x2E), (0x5D, 0x40, 0x37)
    return (0x8D, 0x6E, 0x63), (0x66, 0xBB, 0x6A)


def main() -> int:
    root = ET.parse(XML).getroot()
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for group in root.findall("imgdir"):
        u = group.get("name")
        if u in (None, "info"):
            continue
        for canvas in group.findall("canvas"):
            no = canvas.get("name")
            w, h = int(canvas.get("width", 1)), int(canvas.get("height", 1))
            origin = canvas.find('vector[@name="origin"]')
            ox = int(origin.get("x", 0)) if origin is not None else 0
            oy = int(origin.get("y", 0)) if origin is not None else 0
            dst = os.path.join(OUT, f"{u}_{no}.png")
            if os.path.isfile(dst) and os.path.getsize(dst) >= 200:
                continue
            dirt, grass = _colors(u)
            img = Image.new("RGBA", (max(w, 1), max(h, 1)), (0, 0, 0, 0))
            dr = ImageDraw.Draw(img)
            dr.rectangle([0, h // 3, w, h], fill=dirt + (255,))
            dr.rectangle([0, 0, w, max(4, h // 3)], fill=grass + (255,))
            if u.startswith("enV"):
                dr.line([(w - 2, 0), (w - 2, h)], fill=(0, 0, 0, 80), width=1)
            img.save(dst)
            with open(dst + ".json", "w", encoding="utf-8") as mf:
                json.dump({"ox": ox, "oy": oy, "w": w, "h": h, "placeholder": True}, mf)
            n += 1
            print(f"✓ {u}_{no}.png ({w}x{h})")
    print(f"done placeholders={n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
