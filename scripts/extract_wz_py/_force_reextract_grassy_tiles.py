#!/usr/bin/env python3
"""强制从官方 Map.wz 重新提取 grassySoil tile（覆盖占位 PNG）。

用法:
  python scripts/extract_wz_py/_force_reextract_grassy_tiles.py \\
      --client ~/Downloads/冒险岛079/extracted_client \\
      --out client/assets
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Tuple, Optional

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
sys.path.insert(
    0,
    os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", ".cache", "wz-python"
    ),
)

from wzpy.canvas import decode_canvas  # noqa: E402
from wzpy.properties import (  # noqa: E402
    WzCanvasProperty,
    WzIntProperty,
    WzSubProperty,
    WzStringProperty,
)
from wzpy.wz_file import WzFile  # noqa: E402


def open_wz(client: str) -> WzFile:
    path = os.path.join(client, "Map.wz")
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region="EMS", version=ver)
        except Exception:
            continue
    return WzFile.open(path, region="EMS")


def canvas_origin(canvas: WzCanvasProperty) -> Tuple[int, int]:
    origin = canvas.get("origin")
    if origin is not None and hasattr(origin, "x"):
        return int(origin.x), int(origin.y)
    return 0, 0


def extract_tile(
    wf: WzFile,
    tS: str,
    u: str,
    no: int,
    out_dir: str,
    region: str,
) -> Optional[Tuple[int, int, int, int]]:
    dst = os.path.join(out_dir, "maps", "tiles", tS, f"{u}_{no}.png")
    os.makedirs(os.path.dirname(dst), exist_ok=True)

    node = wf.root.get("Tile").get(f"{tS}.img")
    if node is None:
        print(f"  ✗ {tS}.img 未找到")
        return None
    node.parse()
    group = node.get(u)
    if not isinstance(group, WzSubProperty):
        print(f"  ✗ {tS}/{u} 非子节点")
        return None
    canvas = group.get(str(no))
    if not isinstance(canvas, WzCanvasProperty):
        print(f"  ✗ {tS}/{u}/{no} 非画布")
        return None
    try:
        img = decode_canvas(canvas, region=region)
    except Exception as ex:
        print(f"  ✗ decode 失败: {ex}")
        return None
    ox, oy = canvas_origin(canvas)
    img.save(dst, format="PNG")
    with open(dst + ".json", "w", encoding="utf-8") as mf:
        json.dump(
            {"ox": ox, "oy": oy, "w": img.width, "h": img.height},
            mf,
            ensure_ascii=False,
            indent=2,
        )
    return ox, oy, img.width, img.height


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", default="client/assets")
    ap.add_argument("--region", default="EMS")
    ap.add_argument(
        "--tile-set",
        default="grassySoil",
        help="tile set 名（默认 grassySoil）",
    )
    args = ap.parse_args()

    wf = open_wz(args.client)
    node = wf.root.get("Tile").get(f"{args.tile_set}.img")
    if node is None:
        print(f"[ERROR] {args.tile_set}.img 在 Map.wz Tile 下未找到")
        return 1
    node.parse()

    out_dir = args.out
    # 遍历所有 group / canvas
    total = ok = 0
    for group in node.children():
        if not isinstance(group, WzSubProperty):
            continue
        u = group.name
        if u == "info":
            continue
        for canvas in group.children():
            if not isinstance(canvas, WzCanvasProperty):
                continue
            total += 1
            no_s = canvas.name
            try:
                no = int(no_s)
            except ValueError:
                continue
            res = extract_tile(wf, args.tile_set, u, no, out_dir, args.region)
            if res is None:
                print(f"  ✗ {args.tile_set}/{u}_{no}.png 失败")
            else:
                ox, oy, w, h = res
                print(f"  ✓ {args.tile_set}/{u}_{no}.png  ox={ox},oy={oy},w={w},h={h}")
                ok += 1
    print(f"完成: {ok}/{total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
