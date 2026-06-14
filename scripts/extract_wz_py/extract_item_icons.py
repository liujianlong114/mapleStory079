#!/usr/bin/env python3
"""导出新手期常用 Item.wz 图标（彩虹岛任务/商店）。"""

from __future__ import annotations

import argparse
import os

from extract import Source, resolve_prop, save_canvas

# 彩虹岛新手常见物品 ID
BEGINNER_ITEMS = [
    1302000,  # 锯
    1372005,  # 初级杖
    2000000,  # 红药水
    2000001,  # 橙药水
    2000002,  # 白药水
    2000003,  # 蓝药水
    2010000,  # 苹果
    2010001,  # 肉
    4000000,  # 蓝蜗牛壳
    4000001,  # 红蜗牛壳
    4000019,  # 绿蜗牛壳
    4031801,  # 希娜的推荐信等任务物（若存在）
    4031013,
    4031014,
    4031015,
]


def _item_spec(item_id: int) -> list[tuple]:
    """079 Item.wz 分卷路径；装备类依次尝试 Install / Character/Weapon / Character/Cape 等。"""
    s = f"{item_id:08d}"
    prefix4 = s[:4]
    if 2000000 <= item_id < 3000000:
        return [("Item.wz", f"Consume/{prefix4}.img", (s, "info", "icon"))]
    if 4000000 <= item_id < 5000000 or 4030000 <= item_id < 4040000:
        return [("Item.wz", f"Etc/{prefix4}.img", (s, "info", "icon"))]
    # 装备：Install 分卷 + Character 武器分卷（1302xxx 木剑等）
    paths = [
        ("Item.wz", f"Install/{prefix4}.img"),
        ("Character.wz", f"Weapon/{prefix4}.img"),
        ("Character.wz", f"Cap/{prefix4}.img"),
        ("Character.wz", f"Coat/{prefix4}.img"),
    ]
    return [(wz, path, (s, "info", "icon")) for wz, path in paths]


def _try_extract(src: Source, spec_paths: list) -> tuple | None:
    """按候选路径依次尝试解析 icon / iconRaw。"""
    for entry in spec_paths:
        wz, img_path, inner = entry
        try:
            img, region, _ = src.load_img((wz, img_path))
            node = resolve_prop(img._root, inner)
            if node is None:
                node = resolve_prop(img._root, (*inner[:-1], "iconRaw"))
            if node is not None:
                from wzpy.properties import WzCanvasProperty

                if isinstance(node, WzCanvasProperty):
                    return node, region
        except Exception:
            continue
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", default="client/assets/sprites/item")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    src = Source(args.client)
    os.makedirs(args.out, exist_ok=True)
    ok = fail = 0

    for item_id in BEGINNER_ITEMS:
        out_path = os.path.join(args.out, f"{item_id}.png")
        if not args.force and os.path.isfile(out_path) and os.path.getsize(out_path) >= 80:
            ok += 1
            continue
        spec_paths = _item_spec(item_id)
        try:
            found = _try_extract(src, spec_paths)
            if found is None:
                print(f"✗ {item_id} missing icon")
                fail += 1
                continue
            node, region = found
            save_canvas(node, region, out_path)
            print(f"✓ {item_id}")
            ok += 1
        except Exception as e:
            print(f"✗ {item_id}: {e}")
            fail += 1

    print(f"done ok={ok} fail={fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
