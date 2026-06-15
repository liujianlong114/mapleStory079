#!/usr/bin/env python3
"""从 Map.wz 的 miniMap 节点导出 PNG + 元数据 JSON。

- miniMap PNG -> client/assets/maps/miniMap/{mapId}.png
- miniMap JSON -> client/assets/maps/miniMap/{mapId}.json（width/height/centerX/centerY/mag）

用法：
  PYTHONPATH=.cache/wz-python .cache/wz-python/.venv/bin/python \
    scripts/extract_wz_py/extract_minimap_from_wz.py \
    --client ~/Downloads/冒险岛079/extracted_client \
    --map 000010000 --map-id 1000000 --force
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any, Dict, List, Optional, Tuple

from wzpy.canvas import decode_canvas
from wzpy.properties import WzCanvasProperty, WzIntProperty, WzSubProperty
from wzpy.wz_file import WzFile

try:
    from PIL import Image, ImageDraw  # type: ignore
except Exception:  # noqa: BLE001
    Image = None
    ImageDraw = None

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
MIN_PNG = 400


def open_wz(client: str) -> WzFile:
    path = os.path.join(client, "Map.wz")
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region="EMS", version=ver)
        except Exception:
            continue
    return WzFile.open(path, region="EMS")


def load_map_img(wf: WzFile, map_file: str) -> Optional[WzSubProperty]:
    name = map_file if map_file.endswith(".img") else f"{map_file}.img"
    for map_dir in (
        "Map0", "Map1", "Map2", "Map3", "Map4",
        "Map5", "Map6", "Map7", "Map8", "Map9",
    ):
        d = wf.root.get("Map").get(map_dir)
        if d is None:
            continue
        img = d.get(name)
        if img is not None:
            img.parse()
            return img
    return None


def prop_int(node: WzSubProperty, key: str, default: int = 0) -> int:
    p = node.get(key)
    if isinstance(p, WzIntProperty):
        return int(p.value)
    return default


def collect_canvases(node: Optional[WzSubProperty]) -> List[Tuple[str, WzCanvasProperty]]:
    """递归收 canvas；miniMap 里常见直接 <canvas name="canvas"> 或多个编号 canvas。"""
    if node is None:
        return []
    out: List[Tuple[str, WzCanvasProperty]] = []
    for ch in node.children():
        if isinstance(ch, WzCanvasProperty):
            out.append((ch.name, ch))
        elif isinstance(ch, WzSubProperty):
            out.extend(collect_canvases(ch))
    return out


def extract_one(client: str, map_file: str, map_id: int, force: bool,
                out_dir: str) -> bool:
    print(f"[mini] 解析 Map.wz/{map_file}.img -> mapId={map_id}")
    wf = open_wz(client)
    try:
        img = load_map_img(wf, map_file)
        if img is None:
            print(f"  ✗ 未找到 {map_file}.img")
            return False

        mini_map_node = img.get("miniMap")
        if not isinstance(mini_map_node, WzSubProperty):
            print(f"  ⚠ miniMap 节点缺失（无小地图）")
            return False

        canvases = collect_canvases(mini_map_node)
        if not canvases:
            print(f"  ⚠ miniMap 无 canvas")
            return False

        os.makedirs(out_dir, exist_ok=True)

        # 解码并保存 PNG（多 canvas 时保存第一张为主；其余加后缀）
        saved_any = False
        first_png = os.path.join(out_dir, f"{map_id}.png")
        for idx, (name, canvas) in enumerate(canvases):
            if idx == 0:
                dst = first_png
            else:
                dst = os.path.join(out_dir, f"{map_id}_{idx}.png")
            if os.path.isfile(dst) and not force:
                print(f"  · 跳过已存在: {os.path.basename(dst)}")
                saved_any = True
                continue
            try:
                pil_img = decode_canvas(canvas, region="EMS")
            except Exception as exc:  # noqa: BLE001
                print(f"  ✗ canvas {name} decode 失败: {exc}")
                continue
            if pil_img is None or (pil_img.width * pil_img.height) == 0:
                print(f"  ✗ canvas {name} 空图像")
                continue
            pil_img.save(dst, format="PNG", optimize=False)
            size = os.path.getsize(dst)
            print(f"  ✓ {os.path.basename(dst)} ({pil_img.width}x{pil_img.height}, {size}B)")
            saved_any = True

        if not saved_any:
            return False

        meta: Dict[str, Any] = {
            "width": prop_int(mini_map_node, "width"),
            "height": prop_int(mini_map_node, "height"),
            "centerX": prop_int(mini_map_node, "centerX"),
            "centerY": prop_int(mini_map_node, "centerY"),
            "mag": prop_int(mini_map_node, "mag"),
        }
        # 附带保存 canvas 实际像素尺寸
        first_canvas = canvases[0][1]
        try:
            meta["canvasWidth"] = int(getattr(first_canvas, "width", 0) or 0)
            meta["canvasHeight"] = int(getattr(first_canvas, "height", 0) or 0)
        except Exception:  # noqa: BLE001
            pass

        meta_path = os.path.join(out_dir, f"{map_id}.json")
        with open(meta_path, "w", encoding="utf-8") as f:
            json.dump(meta, f, ensure_ascii=False, indent=2)
        print(f"  ✓ {os.path.basename(meta_path)} = {meta}")
        return True
    finally:
        try:
            wf.close()
        except Exception:  # noqa: BLE001
            pass


def draw_foothold_fallback(map_id: int, out_dir: str, force: bool) -> bool:
    """从 client/assets/maps/{mapId}.json 的 footholds 程序化绘制占位小地图。"""
    if Image is None or ImageDraw is None:
        print("  ✗ 缺少 PIL，无法程序化回退")
        return False

    map_json = os.path.join(REPO_ROOT, "client", "assets", "maps", f"{map_id}.json")
    if not os.path.isfile(map_json):
        print(f"  ✗ 缺少地图 JSON: {map_json}")
        return False
    with open(map_json, "r", encoding="utf-8") as f:
        data = json.load(f)

    footholds = data.get("footholds") or []
    if not footholds:
        print("  ✗ 地图 JSON 无 footholds")
        return False

    vr_left = int(data.get("vrLeft") or 0)
    vr_right = int(data.get("vrRight") or 1)
    vr_top = int(data.get("vrTop") or 0)
    vr_bottom = int(data.get("vrBottom") or 1)

    # 用 footholds 实际范围（更紧凑）
    xs = [int(s.get("x1", 0)) for s in footholds] + [int(s.get("x2", 0)) for s in footholds]
    ys = [int(s.get("y1", 0)) for s in footholds] + [int(s.get("y2", 0)) for s in footholds]
    bbox_l = min(min(xs), vr_left)
    bbox_r = max(max(xs), vr_right)
    bbox_t = min(min(ys), vr_top)
    bbox_b = max(max(ys), vr_bottom)
    world_w = max(bbox_r - bbox_l, 1)
    world_h = max(bbox_b - bbox_t, 1)

    # 缩放到 ~256x128 像素画布（带 padding）
    scale = min(240.0 / world_w, 112.0 / world_h)
    pad_x = int((256 - world_w * scale) / 2)
    pad_y = int((128 - world_h * scale) / 2)

    def wx(world_x: float) -> int:
        return int(pad_x + (world_x - bbox_l) * scale)

    def wy(world_y: float) -> int:
        return int(pad_y + (world_y - bbox_t) * scale)

    img = Image.new("RGBA", (256, 128), (34, 58, 40, 255))
    draw = ImageDraw.Draw(img)

    # 画一条浅色 VR 边界框
    draw.rectangle(
        [wx(vr_left), wy(vr_top), wx(vr_right), wy(vr_bottom)],
        outline=(70, 110, 80, 255),
        width=1,
    )
    # 画 foothold 线
    for seg in footholds:
        x1 = int(seg.get("x1", 0))
        y1 = int(seg.get("y1", 0))
        x2 = int(seg.get("x2", 0))
        y2 = int(seg.get("y2", 0))
        draw.line([(wx(x1), wy(y1)), (wx(x2), wy(y2))], fill=(210, 210, 150, 255), width=1)

    # 画 portal 标记
    for portal in data.get("portals") or []:
        x = int(portal.get("x", 0))
        y = int(portal.get("y", 0))
        px, py = wx(x), wy(y)
        draw.rectangle([px - 2, py - 2, px + 2, py + 2], fill=(120, 200, 255, 255))

    os.makedirs(out_dir, exist_ok=True)
    dst = os.path.join(out_dir, f"{map_id}.png")
    if os.path.isfile(dst) and not force:
        print(f"  · 跳过已存在: {os.path.basename(dst)}")
    else:
        img.save(dst, format="PNG", optimize=False)
        size = os.path.getsize(dst)
        print(f"  ✓ fallback {os.path.basename(dst)} ({img.width}x{img.height}, {size}B)")

    meta = {
        "width": world_w,
        "height": world_h,
        "centerX": int((bbox_l + bbox_r) / 2),
        "centerY": int((bbox_t + bbox_b) / 2),
        "mag": 1,
        "canvasWidth": img.width,
        "canvasHeight": img.height,
        "fallback": True,
    }
    meta_path = os.path.join(out_dir, f"{map_id}.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True, help="extracted_client 目录")
    ap.add_argument("--map", required=True, help="WZ img 名（不含 .img），如 000010000")
    ap.add_argument("--map-id", required=True, type=int, help="本项目 mapId，如 1000000")
    ap.add_argument("--out", default=os.path.join("client", "assets", "maps", "miniMap"))
    ap.add_argument("--force", action="store_true")
    ap.add_argument(
        "--fallback-footholds",
        action="store_true",
        help="WZ 无 miniMap 时，从 client/assets/maps/{mapId}.json footholds 程序化绘制占位",
    )
    args = ap.parse_args()

    out_dir = os.path.join(REPO_ROOT, args.out) if not os.path.isabs(args.out) else args.out
    ok = extract_one(args.client, args.map, args.map_id, args.force, out_dir)
    if not ok and args.fallback_footholds:
        ok = draw_foothold_fallback(args.map_id, out_dir, args.force)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
