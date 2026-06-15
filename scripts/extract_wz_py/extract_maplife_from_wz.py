#!/usr/bin/env python3
"""从 WZ 二进制提取地图 life（NPC / Mob 刷点）。

输出：
  data/maplife/{mapId}.json       ← 服务端可读
  client/assets/maplife/{mapId}.json  ← 前端渲染同步

用法：
  PYTHONPATH=.cache/wz-python .cache/wz-python/.venv/bin/python \
    scripts/extract_wz_py/extract_maplife_from_wz.py \
    --client ~/Downloads/冒险岛079/extracted_client \
    --map 000010000 --map-id 1000000 --force
"""
from __future__ import annotations

import argparse
import json
import os
from typing import Any, Dict, List, Optional, Tuple

from wzpy.properties import WzCanvasProperty, WzIntProperty, WzStringProperty, WzSubProperty
from wzpy.wz_file import WzFile


def open_wz(client: str) -> WzFile:
    path = os.path.join(client, "Map.wz")
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region="EMS", version=ver)
        except Exception:
            continue
    return WzFile.open(path, region="EMS")


def prop_int(node: WzSubProperty, key: str, default: int = 0) -> int:
    p = node.get(key)
    if isinstance(p, WzIntProperty):
        return int(p.value)
    return default


def prop_str(node: WzSubProperty, key: str, default: str = "") -> str:
    p = node.get(key)
    if isinstance(p, WzStringProperty):
        return str(p.value)
    return default


def load_map_img(wf: WzFile, map_file: str) -> WzSubProperty:
    name = map_file if map_file.endswith(".img") else f"{map_file}.img"
    for map_dir in ("Map0", "Map1", "Map2", "Map3", "Map4", "Map5", "Map6", "Map7", "Map8", "Map9"):
        d = wf.root.get("Map").get(map_dir)
        if d is None:
            continue
        img = d.get(name)
        if img is not None:
            img.parse()
            return img
    raise FileNotFoundError(f"Map.wz 中未找到 {name}")


def parse_vr(map_img: WzSubProperty) -> Tuple[int, int, int, int]:
    info = map_img.get("info")
    if not isinstance(info, WzSubProperty):
        return -300, 1200, -600, 600
    return (
        prop_int(info, "VRLeft", -300),
        prop_int(info, "VRRight", 1200),
        prop_int(info, "VRTop", -600),
        prop_int(info, "VRBottom", 600),
    )


def parse_life(map_img: WzSubProperty) -> List[Dict[str, Any]]:
    node = map_img.get("life")
    if not isinstance(node, WzSubProperty):
        return []
    out: List[Dict[str, Any]] = []
    for ch in node.children():
        if not isinstance(ch, WzSubProperty):
            continue
        entry: Dict[str, Any] = {
            "type": prop_str(ch, "type"),
            "id": prop_int(ch, "id"),
            "x": prop_int(ch, "x"),
            "y": prop_int(ch, "y"),
            "cy": prop_int(ch, "cy", 0),
            "fh": prop_int(ch, "fh", 0),
            "rx0": prop_int(ch, "rx0"),
            "rx1": prop_int(ch, "rx1"),
            "mobTime": prop_int(ch, "mobTime", 0),
            "f": prop_int(ch, "f", 0),
            "hide": prop_int(ch, "hide", 0),
        }
        # 清理默认值 0，保持与现有 JSON 字段一致
        for k in ("cy", "fh", "mobTime", "f", "hide"):
            if entry[k] == 0:
                del entry[k]
        out.append(entry)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--map", required=True, help="Map0 下 img 名（不含 .img）")
    ap.add_argument("--map-id", type=int, required=True)
    ap.add_argument("--out", default="data/maplife")
    ap.add_argument("--out-client", default="client/assets/maplife")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    wf = open_wz(args.client)
    map_img = load_map_img(wf, args.map)
    vr = parse_vr(map_img)
    life = parse_life(map_img)

    out = {
        "mapId": args.map_id,
        "wzFile": f"{args.map}.img",
        "vrLeft": vr[0],
        "vrRight": vr[1],
        "vrTop": vr[2],
        "vrBottom": vr[3],
        "life": life,
    }

    for dst_dir in (args.out, args.out_client):
        os.makedirs(dst_dir, exist_ok=True)
        dst = os.path.join(dst_dir, f"{args.map_id}.json")
        with open(dst, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=2)
        print(f"✓ {dst} ({len(life)} life)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
