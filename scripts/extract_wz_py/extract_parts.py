"""从 Character.wz / Character/*.img 提取新手创建用部件 PNG。"""

from __future__ import annotations

import os
from typing import List, Optional, Tuple

from PIL import Image

from wzpy import WzImage, WzKey, detect_region_from_img
from wzpy.canvas import decode_canvas
from wzpy.properties import WzCanvasProperty, WzSubProperty
from wzpy.wz_file import WzFile

PART_IDS: List[int] = [
    2000, 2001,
    20100, 20401, 20402, 21002, 21700, 21201,
    30000, 30027, 30030, 31002, 31047, 31057,
    1040002, 1040006, 1040010, 1041002, 1041006, 1041010, 1041011,
    1060002, 1060006, 1061002, 1061008,
    1072001, 1072005, 1072037, 1072038,
    1302000, 1322005, 1312004,
]

CANVAS_PRIORITY = (
    "body", "hair", "hairOverHead", "face", "pants", "coat", "mail",
    "shoes", "glove", "cap", "weapon", "shield", "arm",
)


def _is_data_client(root: str) -> bool:
    return os.path.isfile(os.path.join(root, "Data", "UI", "Login.img"))


def _load_character_wz(client_root: str, region: str) -> Optional[WzFile]:
    if _is_data_client(client_root):
        path = os.path.join(client_root, "Data", "Character")
        if not os.path.isdir(path):
            return None
        return None  # per-img mode below
    wz = os.path.join(client_root, "Character.wz")
    if not os.path.isfile(wz):
        return None
    for ver in (79, 80, 83):
        try:
            return WzFile.open(wz, region=region, version=ver)
        except Exception:
            continue
    return WzFile.open(wz, region=region)


def _find_img_wz(wz: WzFile, part_id: int) -> Optional[WzImage]:
    name = f"{part_id:08d}.img"
    node = wz.root.get(name)
    if node is not None:
        return node
    for path, img in wz.root.walk_images():
        if path.endswith(name) or path.endswith("/" + name):
            return img
    return None


def _find_img_data(data_root: str, part_id: int) -> Optional[Tuple[WzImage, str]]:
    name = f"{part_id:08d}.img"
    for dirpath, _, files in os.walk(os.path.join(data_root, "Character")):
        if name not in files:
            continue
        path = os.path.join(dirpath, name)
        raw = open(path, "rb").read()
        region = detect_region_from_img(raw) or "EMS"
        img = WzImage.from_bytes(raw, key=WzKey.for_region(region), name=name)
        img.parse()
        return img, region
    return None


def _canvas_from_stand(img: WzImage, region: str) -> Optional[Image.Image]:
    root = img._root
    if root is None:
        return None

    pose_paths = (
        "stand1/0", "stand1/1", "default/face", "default/hair",
        "default", "front/0", "info/icon",
    )
    for pose in pose_paths:
        frame = root.get(pose)
        if isinstance(frame, WzCanvasProperty):
            return decode_canvas(frame, region)
        if isinstance(frame, WzSubProperty):
            pil = _composite_frame(frame, region)
            if pil is not None:
                return pil

    frame = root.get("stand1/0")
    if isinstance(frame, WzSubProperty):
        return _composite_frame(frame, region)
    return None


def _composite_frame(frame: WzSubProperty, region: str) -> Optional[Image.Image]:
    canvases: List[WzCanvasProperty] = []
    for pref in CANVAS_PRIORITY:
        ch = frame.get(pref)
        if isinstance(ch, WzCanvasProperty):
            canvases.append(ch)
    if not canvases:
        for ch in frame.children():
            if isinstance(ch, WzCanvasProperty):
                canvases.append(ch)
    if not canvases:
        return None
    if len(canvases) == 1:
        return decode_canvas(canvases[0], region)
    layers: List[Image.Image] = []
    max_w = max_h = 0
    for c in canvases:
        pil = decode_canvas(c, region)
        layers.append(pil)
        max_w = max(max_w, pil.width)
        max_h = max(max_h, pil.height)
    out = Image.new("RGBA", (max_w, max_h), (0, 0, 0, 0))
    for pil in layers:
        out.alpha_composite(pil, (0, max_h - pil.height))
    return out


def extract_character_parts(
    client_root: str,
    out_dir: str,
    region: str = "EMS",
    force: bool = False,
) -> Tuple[int, int]:
    os.makedirs(out_dir, exist_ok=True)
    ok = fail = 0
    wz = None if _is_data_client(client_root) else _load_character_wz(client_root, region)
    data_root = os.path.join(client_root, "Data") if _is_data_client(client_root) else ""

    for part_id in PART_IDS:
        out_path = os.path.join(out_dir, f"{part_id}.png")
        if not force and os.path.isfile(out_path) and os.path.getsize(out_path) >= 512:
            ok += 1
            continue
        try:
            reg = region
            if wz is not None:
                img = _find_img_wz(wz, part_id)
                if img is None:
                    raise FileNotFoundError(part_id)
                img.parse()
            else:
                found = _find_img_data(data_root, part_id)
                if found is None:
                    raise FileNotFoundError(part_id)
                img, reg = found

            pil = _canvas_from_stand(img, reg)
            if pil is None:
                raise ValueError("no stand1 canvas")
            pil.save(out_path, format="PNG", optimize=False)
            print(f"  ✓ part {part_id} → {part_id}.png ({pil.width}x{pil.height})")
            ok += 1
        except Exception as exc:
            print(f"  ✗ part {part_id}: {exc}")
            fail += 1

    return ok, fail
