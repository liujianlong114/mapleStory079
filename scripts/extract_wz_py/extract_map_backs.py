"""从 Map.wz/Back 导出地图视差背景 PNG。

用法:
  python scripts/extract_wz_py/extract_map_backs.py --client ../mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制 --sets grassySoil
"""

from __future__ import annotations

import argparse
import os
from typing import Iterable, List, Optional, Tuple

from wzpy.canvas import decode_canvas
from wzpy.properties import WzCanvasProperty, WzSubProperty
from wzpy.wz_file import WzFile

MIN_REAL_PNG = 400
DEFAULT_SETS = ("grassySoil", "grassySoil_new", "midForest", "deepForest")


def open_wz(client_root: str, name: str, region: str) -> WzFile:
    path = os.path.join(client_root, name)
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region=region, version=ver)
        except Exception:
            continue
    return WzFile.open(path, region=region)


def iter_canvas(node: Optional[WzSubProperty]) -> Iterable[Tuple[str, WzCanvasProperty]]:
    if node is None:
        return
    for i in range(32):
        c = node.get(str(i))
        if isinstance(c, WzCanvasProperty):
            yield str(i), c
    for child in node.children():
        if isinstance(child, WzCanvasProperty):
            yield child.name, child


def save_canvas(canvas: WzCanvasProperty, region: str, out_path: str) -> bool:
    img = decode_canvas(canvas, region=region)
    if img.width < 4 or img.height < 4:
        return False
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, format="PNG")
    return os.path.getsize(out_path) >= MIN_REAL_PNG


def extract_set(wf: WzFile, set_name: str, out_dir: str, region: str, force: bool) -> int:
    node = wf.root.get(f"Back/{set_name}.img")
    if node is None:
        print(f"  skip {set_name}: not in Map.wz/Back")
        return 0
    node.parse()
    back = node.get("back")
    if not isinstance(back, WzSubProperty):
        print(f"  skip {set_name}: no back node")
        return 0

    dest_dir = os.path.join(out_dir, "maps", "back", set_name)
    os.makedirs(dest_dir, exist_ok=True)
    count = 0
    for name, canvas in iter_canvas(back):
        dst = os.path.join(dest_dir, f"{name}.png")
        if not force and os.path.isfile(dst) and os.path.getsize(dst) >= MIN_REAL_PNG:
            continue
        try:
            if save_canvas(canvas, region, dst):
                count += 1
        except Exception as ex:
            print(f"  warn {set_name}/{name}: {ex}")
    return count


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", default="client/assets")
    ap.add_argument("--sets", nargs="*", default=list(DEFAULT_SETS))
    ap.add_argument("--region", default="EMS")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    if not os.path.isdir(args.client):
        print(f"client not found: {args.client}")
        return 1

    wz = open_wz(args.client, "Map.wz", args.region)
    total = 0
    for s in args.sets:
        n = extract_set(wz, s, args.out, args.region, args.force)
        print(f"✓ {s}: {n} backs → {args.out}/maps/back/{s}/")
        total += n
    print(f"done ({total} images)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
