#!/usr/bin/env python3
"""导出 079 UIWindow.img 背包/装备/属性/技能窗口贴图 + Basic.img 关闭按钮。"""

from __future__ import annotations

import argparse
import os
import sys

from extract import Source, resolve_prop, save_canvas

TAB_STATES = ("normal", "mouseOver", "pressed", "disabled")


def _tab_jobs(prefix: str, window: str, count: int) -> list:
    jobs = []
    for state in ("enabled", "disabled"):
        for i in range(count):
            jobs.append(
                (
                    f"{prefix}/tab_{state}_{i}.png",
                    ("UI.wz", "UIWindow.img"),
                    ("Item" if window == "item" else window.capitalize(), "Tab", state, str(i)),
                )
            )
    return jobs


WINDOW_JOBS = [
    # Item / 背包
    ("images/ui/windows/item_backgrnd.png", ("UI.wz", "UIWindow.img"), ("Item", "backgrnd")),
    ("images/ui/windows/item_full_backgrnd.png", ("UI.wz", "UIWindow.img"), ("Item", "FullBackgrnd")),
    ("images/ui/windows/item_slot_disabled.png", ("UI.wz", "UIWindow.img"), ("Item", "disabled")),
    ("images/ui/windows/item_slot_active.png", ("UI.wz", "UIWindow.img"), ("Item", "activeIcon")),
    # Equip / 装备
    ("images/ui/windows/equip_backgrnd.png", ("UI.wz", "UIWindow.img"), ("Equip", "backgrnd")),
    # Stat / 属性
    ("images/ui/windows/stat_backgrnd.png", ("UI.wz", "UIWindow.img"), ("Stat", "backgrnd")),
    ("images/ui/windows/stat_backgrnd2.png", ("UI.wz", "UIWindow.img"), ("Stat", "backgrnd2")),
    ("images/ui/windows/stat_basic.png", ("UI.wz", "UIWindow.img"), ("Stat", "basicStat")),
    # Skill / 技能
    ("images/ui/windows/skill_backgrnd.png", ("UI.wz", "UIWindow.img"), ("Skill", "backgrnd")),
    ("images/ui/windows/skill_line.png", ("UI.wz", "UIWindow.img"), ("Skill", "line")),
    ("images/ui/windows/skill_row0.png", ("UI.wz", "UIWindow.img"), ("Skill", "skill0")),
    ("images/ui/windows/skill_row1.png", ("UI.wz", "UIWindow.img"), ("Skill", "skill1")),
    # 关闭按钮（079 UI.wz/Basic.img/BtClose）
    *[
        (
            f"images/ui/windows/btn_close_{state}.png",
            ("UI.wz", "Basic.img"),
            ("BtClose", state, "0"),
        )
        for state in TAB_STATES
    ],
    # Item 页签（装备/消耗/其他/设置/特殊）
    *[
        (
            f"images/ui/windows/item_tab_{state}_{i}.png",
            ("UI.wz", "UIWindow.img"),
            ("Item", "Tab", state, str(i)),
        )
        for state in ("enabled", "disabled")
        for i in range(5)
    ],
    # Skill 页签
    *[
        (
            f"images/ui/windows/skill_tab_{state}_{i}.png",
            ("UI.wz", "UIWindow.img"),
            ("Skill", "Tab", state, str(i)),
        )
        for state in ("enabled", "disabled")
        for i in range(5)
    ],
    # Stat AP+
    *[
        (
            f"images/ui/windows/stat_ap_{state}.png",
            ("UI.wz", "UIWindow.img"),
            ("Stat", "BtApUp", state, "0"),
        )
        for state in TAB_STATES
    ],
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", default="client/assets")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    src = Source(args.client)
    ok = fail = 0
    for out_rel, spec, inner in WINDOW_JOBS:
        out_path = os.path.join(args.out, out_rel)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        if not args.force and os.path.isfile(out_path) and os.path.getsize(out_path) >= 100:
            ok += 1
            continue
        try:
            img, region, _ = src.load_img(spec)
            node = resolve_prop(img._root, inner)
            if node is None:
                print(f"✗ missing {spec} {'/'.join(inner)}")
                fail += 1
                continue
            from wzpy.properties import WzCanvasProperty

            if not isinstance(node, WzCanvasProperty):
                print(f"✗ not canvas {out_rel}")
                fail += 1
                continue
            save_canvas(node, region, out_path)
            print(f"✓ {out_rel}")
            ok += 1
        except Exception as e:
            print(f"✗ {out_rel}: {e}")
            fail += 1

    print(f"done ok={ok} fail={fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
