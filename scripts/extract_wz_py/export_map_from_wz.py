#!/usr/bin/env python3
"""从官方 Map.wz 二进制导出地图 JSON + 视差 Back PNG。

用法:
  python scripts/extract_wz_py/export_map_from_wz.py \\
    --client ~/Downloads/冒险岛079/extracted_client \\
    --map 000010000 --map-id 1000000
"""

from __future__ import annotations

import argparse
import json
import os
from typing import Any, Dict, List, Optional, Set, Tuple

from wzpy.canvas import decode_canvas
from wzpy.properties import WzCanvasProperty, WzIntProperty, WzStringProperty, WzSubProperty
from wzpy.wz_file import WzFile

MIN_PNG = 400


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


def parse_back_layers(map_img: WzSubProperty) -> List[Dict[str, Any]]:
    back = map_img.get("back")
    if not isinstance(back, WzSubProperty):
        return []
    layers: List[Dict[str, Any]] = []
    for ch in back.children():
        if not isinstance(ch, WzSubProperty):
            continue
        layers.append(
            {
                "no": prop_int(ch, "no"),
                "type": prop_int(ch, "type"),
                "x": prop_int(ch, "x"),
                "y": prop_int(ch, "y"),
                "rx": prop_int(ch, "rx"),
                "ry": prop_int(ch, "ry"),
                "a": prop_int(ch, "a", 255),
                "bS": prop_str(ch, "bS", "grassySoil"),
            }
        )
    return layers


def bounds_from_footholds(footholds: List[Dict[str, int]]) -> Optional[Tuple[int, int, int, int]]:
    if not footholds:
        return None
    xs: List[int] = []
    ys: List[int] = []
    for s in footholds:
        xs.extend([int(s["x1"]), int(s["x2"])])
        ys.extend([int(s["y1"]), int(s["y2"])])
    return min(xs), max(xs), min(ys), max(ys)


def resolve_viewport(
    info: Dict[str, Any], footholds: List[Dict[str, int]]
) -> Tuple[int, int, int, int]:
    vr_left = int(info.get("vrLeft") or 0)
    vr_right = int(info.get("vrRight") or 0)
    vr_top = int(info.get("vrTop") or 0)
    vr_bottom = int(info.get("vrBottom") or 0)
    if vr_right > vr_left and vr_bottom > vr_top:
        return vr_left, vr_right, vr_top, vr_bottom
    bounds = bounds_from_footholds(footholds)
    if bounds is None:
        return -315, 1390, -480, 750
    min_x, max_x, min_y, max_y = bounds
    margin_x, margin_y = 120, 100
    return (
        min_x - margin_x,
        max_x + margin_x,
        min_y - margin_y,
        max_y + margin_y,
    )


def parse_info(map_img: WzSubProperty) -> Dict[str, Any]:
    info = map_img.get("info")
    if not isinstance(info, WzSubProperty):
        return {}
    return {
        "vrLeft": prop_int(info, "VRLeft"),
        "vrRight": prop_int(info, "VRRight"),
        "vrTop": prop_int(info, "VRTop"),
        "vrBottom": prop_int(info, "VRBottom"),
        "bgm": prop_str(info, "bgm"),
        "mapMark": prop_str(info, "mapMark"),
    }


def parse_footholds(map_img: WzSubProperty) -> List[Dict[str, int]]:
    fh = map_img.get("foothold")
    if not isinstance(fh, WzSubProperty):
        return []
    out: List[Dict[str, int]] = []
    for layer in fh.children():
        if not isinstance(layer, WzSubProperty):
            continue
        for grp in layer.children():
            if not isinstance(grp, WzSubProperty):
                continue
            for seg in grp.children():
                if not isinstance(seg, WzSubProperty):
                    continue
                if seg.get("x1") is None:
                    continue
                out.append(
                    {
                        "x1": prop_int(seg, "x1"),
                        "y1": prop_int(seg, "y1"),
                        "x2": prop_int(seg, "x2"),
                        "y2": prop_int(seg, "y2"),
                    }
                )
    return out


def parse_spawn(map_img: WzSubProperty) -> Tuple[int, int]:
    life = map_img.get("life")
    if not isinstance(life, WzSubProperty):
        return 400, 605
    for ch in life.children():
        if not isinstance(ch, WzSubProperty):
            continue
        if prop_str(ch, "type") == "m" and prop_int(ch, "id") == 0:
            return prop_int(ch, "x", 400), prop_int(ch, "y", 605)
    return 400, 605


def parse_portals(map_img: WzSubProperty) -> List[Dict[str, Any]]:
    node = map_img.get("portal")
    if not isinstance(node, WzSubProperty):
        return []
    out: List[Dict[str, Any]] = []
    for ch in node.children():
        if not isinstance(ch, WzSubProperty):
            continue
        try:
            pid = int(ch.name)
        except ValueError:
            continue
        out.append(
            {
                "id": pid,
                "name": prop_str(ch, "pn"),
                "type": prop_int(ch, "pt"),
                "x": prop_int(ch, "x"),
                "y": prop_int(ch, "y"),
                "targetMap": prop_int(ch, "tm"),
                "targetName": prop_str(ch, "tn"),
            }
        )
    return out


def load_tile_origins_from_xml(tS: str) -> Dict[Tuple[str, int], Tuple[int, int]]:
    """ms079 XML 中的 origin（decode 失败时的回退）。"""
    if tS != "grassySoil":
        return {}
    xml_path = os.environ.get(
        "GRASSY_TILE_XML",
        "/Users/lijianjun/GolandProjects/mapleStory079-external/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML/wz/Map.wz/Tile/grassySoil.img.xml",
    )
    if not os.path.isfile(xml_path):
        return {}
    import xml.etree.ElementTree as ET

    root = ET.parse(xml_path).getroot()
    out: Dict[Tuple[str, int], Tuple[int, int]] = {}
    for group in root.findall("imgdir"):
        u = group.get("name")
        if u in (None, "info"):
            continue
        for canvas in group.findall("canvas"):
            no_s = canvas.get("name")
            if no_s is None:
                continue
            origin = canvas.find('vector[@name="origin"]')
            ox = int(origin.get("x", 0)) if origin is not None else 0
            oy = int(origin.get("y", 0)) if origin is not None else 0
            out[(u, int(no_s))] = (ox, oy)
    return out


def ground_y_at(footholds: List[Dict[str, int]], x: int, feet_y: int, fallback: int = 605) -> int:
    """与 HeavenClient FootholdTree::get_fhid_below 一致：脚下最近可站立面（Y≥脚点）。"""
    ys: List[float] = []
    for s in footholds:
        x1, x2, y1, y2 = s["x1"], s["x2"], s["y1"], s["y2"]
        if abs(x2 - x1) < 1:
            continue
        mn, mx = (x1, x2) if x1 <= x2 else (x2, x1)
        if x < mn - 8 or x > mx + 8:
            continue
        t = (x - x1) / (x2 - x1)
        t = max(0.0, min(1.0, t))
        ys.append(y1 + (y2 - y1) * t)
    if not ys:
        return fallback
    candidates = [y for y in ys if y >= feet_y - 8]
    if not candidates:
        return int(min(ys))
    return int(min(candidates))


def canvas_origin(canvas: WzCanvasProperty) -> Tuple[int, int]:
    origin = canvas.get("origin")
    if origin is not None and hasattr(origin, "x"):
        return int(origin.x), int(origin.y)
    return 0, 0


def parse_map_layers(map_img: WzSubProperty) -> List[Dict[str, Any]]:
    """解析 0–7 层 tile / obj（HeavenClient MapTilesObjs）。"""
    out: List[Dict[str, Any]] = []
    for ch in map_img.children():
        if not isinstance(ch, WzSubProperty):
            continue
        lid = ch.name
        if not lid.isdigit():
            continue
        layer_id = int(lid)
        info = ch.get("info")
        tS = ""
        if isinstance(info, WzSubProperty):
            tS = prop_str(info, "tS")
        tiles: List[Dict[str, Any]] = []
        tile_node = ch.get("tile")
        if isinstance(tile_node, WzSubProperty):
            for t in tile_node.children():
                if not isinstance(t, WzSubProperty):
                    continue
                tiles.append(
                    {
                        "x": prop_int(t, "x"),
                        "y": prop_int(t, "y"),
                        "u": prop_str(t, "u"),
                        "no": prop_int(t, "no"),
                        "zM": prop_int(t, "zM"),
                    }
                )
        objs: List[Dict[str, Any]] = []
        obj_node = ch.get("obj")
        if isinstance(obj_node, WzSubProperty):
            for o in obj_node.children():
                if not isinstance(o, WzSubProperty):
                    continue
                objs.append(
                    {
                        "x": prop_int(o, "x"),
                        "y": prop_int(o, "y"),
                        "oS": prop_str(o, "oS"),
                        "l0": prop_str(o, "l0"),
                        "l1": prop_str(o, "l1"),
                        "l2": prop_str(o, "l2"),
                        "z": prop_int(o, "z"),
                        "f": prop_int(o, "f"),
                        "zM": prop_int(o, "zM"),
                    }
                )
        if tiles or objs:
            out.append({"id": layer_id, "tS": tS, "tiles": tiles, "objs": objs})
    out.sort(key=lambda L: L["id"])
    return out


def export_tile_from_data_client(
    data_client: str, tS: str, u: str, no: int, out_dir: str, region: str, force: bool
) -> Optional[Tuple[int, int]]:
    import sys

    sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
    from extract import Source, save_canvas  # noqa: WPS433

    dst = os.path.join(out_dir, "maps", "tiles", tS, f"{u}_{no}.png")
    if not force and os.path.isfile(dst) and os.path.getsize(dst) >= 80:
        meta_path = dst + ".json"
        if os.path.isfile(meta_path):
            with open(meta_path, encoding="utf-8") as mf:
                meta = json.load(mf)
            return int(meta.get("ox", 0)), int(meta.get("oy", 0))
        return 0, 0
    try:
        src = Source(data_client, region=region)
        img, reg, _ = src.load_img((f"Map/Tile/{tS}.img",))
        group = img.get(u)
        if group is None:
            return None
        canvas = group.get(str(no))
        if canvas is None:
            return None
        save_canvas(canvas, reg, dst)
        ox, oy = 0, 0
        origin = canvas.get("origin") if hasattr(canvas, "get") else None
        if origin is not None and hasattr(origin, "x"):
            ox, oy = int(origin.x), int(origin.y)
        with open(dst + ".json", "w", encoding="utf-8") as mf:
            json.dump({"ox": ox, "oy": oy}, mf)
        return ox, oy
    except Exception as ex:
        print(f"  warn Data tile {tS}/{u}/{no}: {ex}")
        return None


def export_tile_png(
    wf: WzFile,
    tS: str,
    u: str,
    no: int,
    out_dir: str,
    region: str,
    force: bool,
    data_client: str = "",
) -> Optional[Tuple[int, int]]:
    if not tS or tS == "None":
        return None
    dst = os.path.join(out_dir, "maps", "tiles", tS, f"{u}_{no}.png")
    if not force and os.path.isfile(dst) and os.path.getsize(dst) >= 80:
        try:
            from PIL import Image

            w, h = Image.open(dst).size
            meta_path = dst + ".json"
            if os.path.isfile(meta_path):
                with open(meta_path, encoding="utf-8") as mf:
                    meta = json.load(mf)
                return int(meta.get("ox", 0)), int(meta.get("oy", 0))
            return 0, 0
        except Exception:
            pass
    node = wf.root.get("Tile").get(f"{tS}.img")
    if node is None:
        if data_client:
            return export_tile_from_data_client(
                data_client, tS, u, no, out_dir, region, force
            )
        return None
    node.parse()
    group = node.get(u)
    if not isinstance(group, WzSubProperty):
        if data_client:
            return export_tile_from_data_client(
                data_client, tS, u, no, out_dir, region, force
            )
        return None
    canvas = group.get(str(no))
    if not isinstance(canvas, WzCanvasProperty):
        if data_client:
            return export_tile_from_data_client(
                data_client, tS, u, no, out_dir, region, force
            )
        return None
    try:
        img = decode_canvas(canvas, region=region)
    except Exception:
        if data_client:
            return export_tile_from_data_client(
                data_client, tS, u, no, out_dir, region, force
            )
        return None
    ox, oy = canvas_origin(canvas)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst, format="PNG")
    with open(dst + ".json", "w", encoding="utf-8") as mf:
        json.dump({"ox": ox, "oy": oy, "w": img.width, "h": img.height}, mf)
    return ox, oy


def export_obj_png(
    wf: WzFile,
    oS: str,
    l0: str,
    l1: str,
    l2: str,
    out_dir: str,
    region: str,
    force: bool,
) -> Optional[Tuple[int, int]]:
    if not oS:
        return None
    safe = f"{l0}_{l1}_{l2}".replace("/", "_")
    dst = os.path.join(out_dir, "maps", "obj", oS, f"{safe}.png")
    if not force and os.path.isfile(dst) and os.path.getsize(dst) >= 80:
        meta_path = dst + ".json"
        if os.path.isfile(meta_path):
            with open(meta_path, encoding="utf-8") as mf:
                meta = json.load(mf)
            return int(meta.get("ox", 0)), int(meta.get("oy", 0))
        return 0, 0
    node = wf.root.get("Obj").get(f"{oS}.img")
    if node is None:
        return None
    node.parse()
    branch = node.get(l0)
    if not isinstance(branch, WzSubProperty):
        return None
    branch = branch.get(l1)
    if not isinstance(branch, WzSubProperty):
        return None
    frame = branch.get(str(l2))
    if isinstance(frame, WzSubProperty):
        canvas = frame.get("0")
    elif isinstance(frame, WzCanvasProperty):
        canvas = frame
    else:
        return None
    if not isinstance(canvas, WzCanvasProperty):
        return None
    try:
        img = decode_canvas(canvas, region=region)
    except Exception:
        return None
    ox, oy = canvas_origin(canvas)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst, format="PNG")
    with open(dst + ".json", "w", encoding="utf-8") as mf:
        json.dump({"ox": ox, "oy": oy, "w": img.width, "h": img.height}, mf)
    return ox, oy


def export_back_from_data_client(
    data_client: str, bS: str, no: int, out_dir: str, region: str, force: bool
) -> bool:
    """MAX3 等 Data/Map/Back/{set}.img 回退（官方 Map.wz 常缺 grassySoil.img）。"""
    import sys

    sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
    from extract import Source, save_canvas  # noqa: WPS433

    dst = os.path.join(out_dir, "maps", "back", bS, f"{no}.png")
    if not force and os.path.isfile(dst) and os.path.getsize(dst) >= MIN_PNG:
        return True
    try:
        src = Source(data_client, region=region)
        img, reg, _ = src.load_img((f"Map/Back/{bS}.img",))
        back = img.get("back")
        if back is None:
            return False
        canvas = back.get(str(no))
        if canvas is None:
            return False
        save_canvas(canvas, reg, dst)
        return os.path.getsize(dst) >= MIN_PNG
    except Exception as ex:
        print(f"  warn Data back {bS}/{no}: {ex}")
        return False


def export_back_png(
    wf: WzFile, bS: str, no: int, out_dir: str, region: str, force: bool
) -> bool:
    dst = os.path.join(out_dir, "maps", "back", bS, f"{no}.png")
    if not force and os.path.isfile(dst) and os.path.getsize(dst) >= MIN_PNG:
        return True
    node = wf.root.get("Back").get(f"{bS}.img")
    if node is None:
        return False
    node.parse()
    back = node.get("back")
    if not isinstance(back, WzSubProperty):
        return False
    canvas = back.get(str(no))
    if not isinstance(canvas, WzCanvasProperty):
        return False
    img = decode_canvas(canvas, region=region)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst, format="PNG")
    return os.path.getsize(dst) >= MIN_PNG


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--map", default="000010000", help="Map0 下 img 名（不含 .img）")
    ap.add_argument("--map-id", type=int, default=1000000)
    ap.add_argument("--name", default="彩虹村")
    ap.add_argument("--out", default="client/assets")
    ap.add_argument("--back-client", default="", help="Data 客户端，补 grassySoil 等 Back")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    wf = open_wz(args.client)
    map_img = load_map_img(wf, args.map)
    info = parse_info(map_img)
    layers = parse_back_layers(map_img)
    footholds = parse_footholds(map_img)
    map_layers = parse_map_layers(map_img)
    portals = parse_portals(map_img)
    spawn_x, _ = parse_spawn(map_img)
    spawn_y = ground_y_at(footholds, spawn_x, 605)

    vr_left, vr_right, vr_top, vr_bottom = resolve_viewport(info, footholds)

    manifest = {
        "mapId": args.map_id,
        "name": args.name,
        "bgm": info.get("bgm") or "Bgm00/FloralLife",
        "vrLeft": vr_left,
        "vrRight": vr_right,
        "vrTop": vr_top,
        "vrBottom": vr_bottom,
        "width": vr_right - vr_left,
        "height": vr_bottom - vr_top,
        "mapMark": info.get("mapMark") or "MushroomVillage",
        "layers": layers,
        "mapLayers": map_layers,
        "footholds": footholds,
        "portals": portals,
        "spawnX": spawn_x,
        "spawnY": spawn_y,
    }

    out_json = os.path.join(args.out, "maps", f"{args.map_id}.json")
    os.makedirs(os.path.dirname(out_json), exist_ok=True)

    tile_keys: Set[Tuple[str, str, int]] = set()
    obj_keys: Set[Tuple[str, str, str, str]] = set()
    for ml in map_layers:
        tS = ml.get("tS") or "grassySoil"
        for t in ml.get("tiles", []):
            if t.get("u"):
                tile_keys.add((tS, t["u"], int(t["no"])))
        for o in ml.get("objs", []):
            if o.get("oS"):
                obj_keys.add((o["oS"], o["l0"], o["l1"], str(o["l2"])))

    tile_origins: Dict[Tuple[str, str, int], Tuple[int, int]] = {}
    tok = 0
    back_client = args.back_client or os.environ.get("MAPLE_BACK_CLIENT", "")
    for tS, u, no in sorted(tile_keys):
        origin = export_tile_png(
            wf, tS, u, no, args.out, "EMS", args.force, data_client=back_client
        )
        if origin:
            tile_origins[(tS, u, no)] = origin
            tok += 1
    print(f"✓ tile PNG {tok}/{len(tile_keys)}")

    obj_origins: Dict[Tuple[str, str, str, str], Tuple[int, int]] = {}
    ook = 0
    for oS, l0, l1, l2 in sorted(obj_keys):
        origin = export_obj_png(wf, oS, l0, l1, l2, args.out, "EMS", args.force)
        if origin:
            obj_origins[(oS, l0, l1, l2)] = origin
            ook += 1
    print(f"✓ obj PNG {ook}/{len(obj_keys)}")

    xml_origins = load_tile_origins_from_xml("grassySoil")

    for ml in map_layers:
        tS = ml.get("tS") or "grassySoil"
        kept_tiles = []
        for t in ml.get("tiles", []):
            key = (tS, t.get("u", ""), int(t.get("no", 0)))
            ox, oy = tile_origins.get(key, (0, 0))
            if key not in tile_origins:
                u, no = key[1], key[2]
                png_path = os.path.join(args.out, "maps", "tiles", tS, f"{u}_{no}.png")
                if os.path.isfile(png_path) and os.path.getsize(png_path) >= 40:
                    meta_path = png_path + ".json"
                    if os.path.isfile(meta_path):
                        with open(meta_path, encoding="utf-8") as mf:
                            meta = json.load(mf)
                        ox, oy = int(meta.get("ox", 0)), int(meta.get("oy", 0))
                    else:
                        ox, oy = xml_origins.get((u, no), (0, 0))
                else:
                    continue
            t["ox"] = ox
            t["oy"] = oy
            kept_tiles.append(t)
        ml["tiles"] = kept_tiles
        kept_objs = []
        for o in ml.get("objs", []):
            key = (o.get("oS", ""), o.get("l0", ""), o.get("l1", ""), str(o.get("l2", "")))
            if key not in obj_origins:
                continue
            ox, oy = obj_origins[key]
            o["ox"] = ox
            o["oy"] = oy
            kept_objs.append(o)
        ml["objs"] = kept_objs

    manifest["mapLayers"] = map_layers
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print(
        f"✓ map JSON → {out_json} "
        f"({len(layers)} back, {len(map_layers)} fg layers, {len(footholds)} footholds)"
    )

    back_client = args.back_client or os.environ.get("MAPLE_BACK_CLIENT", "")
    needed: Set[Tuple[str, int]] = {(L["bS"], L["no"]) for L in layers}
    ok = 0
    for bS, no in sorted(needed):
        if export_back_png(wf, bS, no, args.out, "EMS", args.force):
            ok += 1
            print(f"  ✓ back/{bS}/{no}.png")
        elif back_client and export_back_from_data_client(
            back_client, bS, no, args.out, "EMS", args.force
        ):
            ok += 1
            print(f"  ✓ back/{bS}/{no}.png (Data 客户端)")
        else:
            print(f"  ✗ back/{bS}/{no}.png")
    print(f"✓ back PNG {ok}/{len(needed)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
