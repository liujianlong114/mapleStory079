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
    """079 Item.wz 分卷规则；装备在 Character/* 下按完整 8 位 ID 建 .img。"""
    s = f"{item_id:08d}"
    prefix4 = s[:4]
    if 2000000 <= item_id < 3000000:
        return [("Item.wz", f"Consume/{prefix4}.img", (s, "info", "icon"))]
    if 4000000 <= item_id < 5000000 or 4030000 <= item_id < 4040000:
        return [("Item.wz", f"Etc/{prefix4}.img", (s, "info", "icon"))]
    if 1000000 <= item_id < 2000000:
        # 对照 extract_beginner_parts：武器/防具在 Character 子目录
        if 1300000 <= item_id < 1500000:
            sub = "Weapon"
        elif 1100000 <= item_id < 1200000:
            sub = "Cap"
        elif 1040000 <= item_id < 1050000:
            sub = "Coat"
        elif 1060000 <= item_id < 1070000:
            sub = "Pants"
        elif 1070000 <= item_id < 1080000:
            sub = "Shoes"
        elif 1370000 <= item_id < 1380000:
            sub = "Weapon"  # 杖类
        else:
            sub = "Weapon"
        return [
            ("Item.wz", f"Character/{sub}/{s}.img", (s, "info", "icon")),
            ("Item.wz", f"Character/{sub}/{s}.img", (s, "icon")),
            ("Item.wz", f"Install/{prefix4}.img", (s, "info", "icon")),
        ]
    return [("Item.wz", f"Install/{prefix4}.img", (s, "info", "icon"))]


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
        specs = _item_spec(item_id)
        try:
            node = None
            region = None
            for wz_file, img_path, inner in specs:
                try:
                    img, region, _ = src.load_img((wz_file, img_path))
                    node = resolve_prop(img._root, inner)
                    if node is None:
                        node = resolve_prop(img._root, (*inner[:-1], "iconRaw"))
                    if node is not None:
                        break
                except Exception:
                    continue
            if node is None:
                print(f"✗ {item_id} missing icon")
                fail += 1
                continue
            from wzpy.properties import WzCanvasProperty

            if not isinstance(node, WzCanvasProperty):
                print(f"✗ {item_id} not canvas")
                fail += 1
                continue
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
