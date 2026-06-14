#!/usr/bin/env python3
"""导出 079 游戏内 HUD：StatusBar.img + UIWindow.img/MiniMap + MapHelper 标记。"""

from __future__ import annotations

import argparse
import os
import sys

from extract import Source, resolve_prop, save_canvas

HUD_JOBS = [
    # StatusBar 底栏
    ("images/ui/hud/status_backgrnd.png", ("UI.wz", "StatusBar.img"), ("base", "backgrnd")),
    ("images/ui/hud/status_backgrnd2.png", ("UI.wz", "StatusBar.img"), ("base", "backgrnd2")),
    ("images/ui/hud/exp_graduation.png", ("UI.wz", "StatusBar.img"), ("gauge", "graduation")),
    ("images/ui/hud/exp_bar_bg.png", ("UI.wz", "StatusBar.img"), ("gauge", "bar")),
    ("images/ui/hud/gauge_gray.png", ("UI.wz", "StatusBar.img"), ("gauge", "gray")),
    ("images/ui/hud/gauge_temp_exp.png", ("UI.wz", "StatusBar.img"), ("gauge", "tempExp")),
    ("images/ui/hud/hp_gauge.png", ("UI.wz", "StatusBar.img"), ("gauge", "hpFlash", "0")),
    ("images/ui/hud/mp_gauge.png", ("UI.wz", "StatusBar.img"), ("gauge", "mpFlash", "0")),
    ("images/ui/hud/icon_red.png", ("UI.wz", "StatusBar.img"), ("base", "iconRed")),
    ("images/ui/hud/icon_blue.png", ("UI.wz", "StatusBar.img"), ("base", "iconBlue")),
    # 菜单按钮
    ("images/ui/hud/btn_shop_normal.png", ("UI.wz", "StatusBar.img"), ("BtShop", "normal", "0")),
    ("images/ui/hud/btn_menu_normal.png", ("UI.wz", "StatusBar.img"), ("BtMenu", "normal", "0")),
    ("images/ui/hud/btn_chat_normal.png", ("UI.wz", "StatusBar.img"), ("BtChat", "normal", "0")),
    ("images/ui/hud/key_equip.png", ("UI.wz", "StatusBar.img"), ("EquipKey",)),
    ("images/ui/hud/key_inven.png", ("UI.wz", "StatusBar.img"), ("InvenKey",)),
    ("images/ui/hud/key_stat.png", ("UI.wz", "StatusBar.img"), ("StatKey",)),
    ("images/ui/hud/key_skill.png", ("UI.wz", "StatusBar.img"), ("SkillKey",)),
    ("images/ui/hud/key_keyset.png", ("UI.wz", "StatusBar.img"), ("KeySet",)),
    # 数字（HP/MP/EXP 位图字）
    *[
        (f"images/ui/hud/num_{d}.png", ("UI.wz", "StatusBar.img"), ("number", str(d)))
        for d in range(10)
    ],
    ("images/ui/hud/num_percent.png", ("UI.wz", "StatusBar.img"), ("number", "percent")),
    ("images/ui/hud/num_slash.png", ("UI.wz", "StatusBar.img"), ("number", "slash")),
    # 小地图框（079 UIWindow.img）
    ("images/ui/hud/minimap_title.png", ("UI.wz", "UIWindow.img"), ("MiniMap", "title")),
    ("images/ui/hud/minimap_btn_map_normal.png", ("UI.wz", "UIWindow.img"), ("MiniMap", "BtMap", "normal", "0")),
    *[
        (f"images/ui/hud/minimap_frame_{name}.png", ("UI.wz", "UIWindow.img"), ("MiniMap", "MinMap", name))
        for name in ("nw", "n", "ne", "w", "c", "e", "sw", "s", "se")
    ],
    *[
        (f"images/ui/hud/minimap_max_{name}.png", ("UI.wz", "UIWindow.img"), ("MiniMap", "MaxMap", name))
        for name in ("nw", "n", "ne", "w", "c", "e", "sw", "s", "se")
    ],
    # 小地图标记
    ("images/ui/hud/marker_user.png", ("Map.wz", "MapHelper.img"), ("minimap", "user")),
    ("images/ui/hud/marker_npc.png", ("Map.wz", "MapHelper.img"), ("minimap", "npc")),
    ("images/ui/hud/marker_portal.png", ("Map.wz", "MapHelper.img"), ("minimap", "portal")),
    ("images/ui/hud/marker_other.png", ("Map.wz", "MapHelper.img"), ("minimap", "another")),
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", default="client/assets")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    src = Source(args.client)
    ok = fail = 0
    for out_rel, spec, inner in HUD_JOBS:
        out_path = os.path.join(args.out, out_rel)
        if not args.force and os.path.isfile(out_path) and os.path.getsize(out_path) >= 200:
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

    # 彩虹村 minimap 缩略图
    try:
        img, region, _ = src.load_img(("Map.wz", "MapHelper.img"))
        node = resolve_prop(img._root, ("minimap", "user"))
        from wzpy.properties import WzCanvasProperty

        if isinstance(node, WzCanvasProperty):
            out_path = os.path.join(args.out, "images/ui/hud/minimap_1000000.png")
            if args.force or not os.path.isfile(out_path):
                save_canvas(node, region, out_path)
                print("✓ images/ui/hud/minimap_1000000.png")
                ok += 1
    except Exception as e:
        print(f"✗ minimap_1000000: {e}")
        fail += 1

    print(f"done ok={ok} fail={fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
