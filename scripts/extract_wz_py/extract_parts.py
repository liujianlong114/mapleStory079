"""从 Character.wz / Character/*.img 提取新手创建用部件 PNG + 元数据（anchor/z-slot）。
用于本地 Dart LocalCharacterComposer（离线时无需后端 /look/compose.png）。
"""

from __future__ import annotations

import json
import os
from typing import Any, Dict, List, Optional, Tuple

from PIL import Image

from wzpy import WzImage, WzKey, detect_region_from_img
from wzpy.canvas import decode_canvas
from wzpy.properties import WzCanvasProperty, WzSubProperty, WzVectorProperty, WzUolProperty
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

# 079 完整装备 ID 范围（用于元数据导出时识别部件类别）
_EXTRA_PART_IDS: List[int] = [
    # Cap (100)
    1040002, 1040006, 1040010, 1041002, 1041006, 1041010, 1041011, 1042167,
    # Cape (110)
    1102005, 1102100,
    # Glove (108)
    1082002, 1082005, 1082016, 1082052,
    # Shield (109)
    1092000, 1098000,
    # 更多鞋子 (107)
    1072001, 1072005, 1072037, 1072038, 1072383,
]

CANVAS_PRIORITY = (
    "body", "hair", "hairOverHead", "face", "pants", "coat", "mail",
    "shoes", "glove", "cap", "weapon", "shield", "arm",
)

# 嵌入的 z-map（来自 wzpy/character.py _DEFAULT_ZMAP，按绘制顺序 back→front）
_EMBEDDED_ZMAP: Tuple[str, ...] = (
    "Bd", "Hd", "Hr", "Fc", "At", "Af", "Am", "Ae", "As", "Ay",
    "Cp", "Ri", "Gv", "Wp", "Si", "So", "Pn", "Ws", "Ma", "Wg",
    "Sr", "Tm", "Sd",
    "backTamingMobMid", "backMobEquipUnderSaddle", "backSaddle",
    "backMobEquipMid", "backTamingMobFront", "backMobEquipFront",
    "mobEquipRear", "tamingMobRear", "saddleRear",
    "characterEnd",
    "backWeaponEffectUnder", "backWeapon", "backWeaponEffectOver",
    "backHairBelowHead", "backShieldBelowBody", "backMailChestAccessory",
    "backCapAccessory", "backAccessoryFace", "backAccessoryEar",
    "backBody", "backGlove", "backGloveWrist",
    "backWeaponOverGloveEffectUnder", "backWeaponOverGlove", "backWeaponOverGloveEffectOver",
    "backMailChestBelowPants", "backPantsBelowShoes", "backShoesBelowPants",
    "backPants", "backShoes", "backPantsOverShoesBelowMailChest",
    "backMailChest", "backPantsOverMailChest", "backMailChestOverPants",
    "backHead", "backAccessoryFaceOverHead", "backAccessoryOverHead",
    "backCape", "backHairBelowCap", "backHairBelowCapNarrow", "backHairBelowCapWide",
    "backWeaponOverHeadEffectUnder", "backWeaponOverHead", "backWeaponOverHeadEffectOver",
    "backCap", "backHair", "backCapOverHair",
    "backShield", "backWeaponOverShieldEffectUnder", "backWeaponOverShield", "backWeaponOverShieldEffectOver",
    "backWing", "backHairOverCape",
    "weaponBelowBodyEffectUnder", "weaponBelowBody", "weaponBelowBodyEffectOver",
    "hairBelowBody", "capeBelowBody", "shieldBelowBody",
    "capAccessoryBelowBody", "gloveBelowBody", "gloveWristBelowBody",
    "body", "gloveOverBody", "mailChestBelowPants", "pantsBelowShoes",
    "shoes", "pants", "mailChestOverPants", "shoesOverPants",
    "pantsOverShoesBelowMailChest", "shoesTop", "mailChest",
    "pantsOverMailChest", "mailChestOverHighest", "gloveWristOverBody",
    "mailChestTop", "capeBelowWeapon",
    "weaponOverBodyEffectUnder", "weaponOverBody", "weaponOverBodyEffectOver",
    "armBelowHead", "mailArmBelowHead", "armBelowHeadOverMailChest",
    "gloveBelowHead", "mailArmBelowHeadOverMailChest", "gloveWristBelowHead",
    "weaponOverArmBelowHeadEffectUnder", "weaponOverArmBelowHead", "weaponOverArmBelowHeadEffectOver",
    "shield", "weaponEffectUnder", "weapon", "weaponEffectOver",
    "arm", "hand", "glove", "mailArm", "gloveWrist",
    "cape", "head", "hairShade",
    "accessoryFaceBelowFace", "accessoryEyeBelowFace",
    "face", "accessoryFaceOverFaceBelowCap", "capBelowAccessory",
    "accessoryEar", "capAccessoryBelowAccFace", "accessoryFace",
    "accessoryEyeShadow", "accessoryEye", "capeOverFace",
    "hair", "cap", "capAccessory", "accessoryEyeOverCap",
    "hairOverHead", "accessoryOverHair", "accessoryEarOverHair",
    "capOverHair",
    "weaponBelowArmEffectUnder", "weaponBelowArm", "weaponBelowArmEffectOver",
    "armOverHairBelowWeapon", "mailArmOverHairBelowWeapon", "armOverHair",
    "gloveBelowMailArm", "mailArmOverHair", "gloveWristBelowMailArm",
    "weaponOverArmEffectUnder", "weaponOverArm", "weaponOverArmEffectOver",
    "handBelowWeapon", "gloveBelowWeapon", "gloveWristBelowWeapon",
    "shieldOverHair",
    "weaponOverHandEffectUnder", "weaponOverHand", "weaponOverHandEffectOver",
    "handOverHair", "gloveOverHair", "gloveWristOverHair",
    "weaponOverGloveEffectUnder", "weaponOverGlove", "weaponOverGloveEffectOver",
    "capeOverHead",
    "weaponWristOverGloveEffectUnder", "weaponWristOverGlove", "weaponWristOverGloveEffectOver",
    "emotionOverBody", "characterStart",
    "backSaddleFront", "saddleMid", "tamingMobMid",
    "mobEquipUnderSaddle", "saddleFront", "mobEquipMid",
    "tamingMobFront", "mobEquipFront",
)


def _z_index(slot: Optional[str]) -> int:
    """Map z-slot name to integer index (lower = drawn first/behind)."""
    if not slot:
        return len(_EMBEDDED_ZMAP)
    try:
        return _EMBEDDED_ZMAP.index(slot)
    except ValueError:
        # Unknown slot: heuristic placement
        s = slot.lower()
        if s.startswith("back"):
            try:
                base = slot[4].lower() + slot[5:] if len(slot) > 4 else slot
                return max(1, _z_index(base) - 5)
            except (ValueError, IndexError):
                pass
            for sep, delta in (("Below", -1), ("Over", 1)):
                if sep.lower() in s:
                    tail = s.split(sep.lower())[-1]
                    sib = "back" + tail[:1].upper() + tail[1:] if tail else ""
                    if sib in _EMBEDDED_ZMAP:
                        return max(1, _z_index(sib) + delta)
            return max(1, _z_index("body") - 1)
        for sep in ("Below", "below"):
            if sep in s:
                target = s.split(sep)[-1]
                target = target[0].upper() + target[1:] if target else target
                try:
                    return max(1, _z_index(target) - 1)
                except ValueError:
                    pass
        for sep in ("Over", "over"):
            if sep.lower() in s:
                tail = s.split(sep.lower())[-1]
                tail_capped = tail[:1].upper() + tail[1:] if tail else tail
                try:
                    return min(len(_EMBEDDED_ZMAP) - 1, _z_index(tail_capped) + 1)
                except ValueError:
                    pass
        return len(_EMBEDDED_ZMAP) - 1


def _resolve_uol(node: Optional[Any]) -> Optional[Any]:
    """Follow a UOL chain to its non-UOL target."""
    seen: set = set()
    cur = node
    for _ in range(16):
        if cur is None or not isinstance(cur, WzUolProperty):
            return cur
        if id(cur) in seen:
            return None
        seen.add(id(cur))
        target_str = getattr(cur, 'value', None)
        if not target_str or not hasattr(cur, 'parent') or cur.parent is None:
            return None
        cur = cur.parent.get(target_str)
    return cur


def _vec(prop: Optional[Any]) -> Optional[Tuple[int, int]]:
    p = _resolve_uol(prop) if prop is not None else None
    if isinstance(p, WzVectorProperty):
        return (p.x, p.y)
    return None


def _origin(canvas: WzCanvasProperty) -> Tuple[int, int]:
    return _vec(canvas.child("origin")) or (0, 0)


def _map_anchors(canvas: WzCanvasProperty) -> Dict[str, Tuple[int, int]]:
    """All ``map/<name>`` vectors as a dict (UOL-resolved)."""
    out: Dict[str, Tuple[int, int]] = {}
    map_node = canvas.child("map")
    if isinstance(map_node, WzSubProperty):
        for c in map_node.children():
            v = _vec(c)
            if v is not None:
                out[c.name] = v
    return out


def _z_slot(canvas: WzCanvasProperty) -> Optional[str]:
    str_prop = canvas.child("z")
    str_prop = _resolve_uol(str_prop) if isinstance(str_prop, WzUolProperty) else str_prop
    if str_prop and hasattr(str_prop, 'value'):
        return str(str_prop.value)
    return None


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


def _collect_stand_canvases(
    img: WzImage, region: str,
) -> List[Dict[str, Any]]:
    """Collect all canvas leaves from stand1/0 with their metadata.
    
    Returns list of dicts: {name, origin_x, origin_y, map_anchors: {name: {x,y}}, z_slot, width, height}
    """
    root = img._root
    if root is None:
        return []
    
    # Try stand1/0 first (body frame), then fall back to default
    frame_paths = ("stand1/0", "stand1/1", "default")
    frame_node = None
    for path in frame_paths:
        node = root.get(path)
        if isinstance(node, WzSubProperty):
            frame_node = node
            break
        if isinstance(node, WzCanvasProperty):
            # Single canvas node
            canvases = []
            ox, oy = _origin(node)
            anchors = _map_anchors(node)
            z = _z_slot(node)
            try:
                pil = decode_canvas(node, region)
                w, h = pil.width, pil.height
            except Exception:
                w, h = 0, 0
            return [{
                "name": node.name,
                "origin_x": ox, "origin_y": oy,
                "map_anchors": {k: {"x": v[0], "y": v[1]} for k, v in anchors.items()},
                "z_slot": z,
                "width": w, "height": h,
                "z_index": _z_index(z),
            }]
    
    if frame_node is None:
        return []
    
    # Collect all canvas children with metadata
    out: List[Dict[str, Any]] = []
    for child in frame_node.children():
        target = _resolve_uol(child) if isinstance(child, WzUolProperty) else child
        if not isinstance(target, WzCanvasProperty):
            continue
        if not target.has_pixels():
            continue
        try:
            pil = decode_canvas(target, region)
            w, h = pil.width, pil.height
        except Exception:
            w, h = 0, 0
        ox, oy = _origin(target)
        anchors = _map_anchors(target)
        z = _z_slot(target)
        out.append({
            "name": child.name,
            "origin_x": ox, "origin_y": oy,
            "map_anchors": {k: {"x": v[0], "y": v[1]} for k, v in anchors.items()},
            "z_slot": z,
            "width": w, "height": h,
            "z_index": _z_index(z),
        })
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
        out_png = os.path.join(out_dir, f"{part_id}.png")
        out_json = os.path.join(out_dir, f"{part_id}.json")
        if not force and os.path.isfile(out_png) and os.path.getsize(out_png) >= 512:
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
            pil.save(out_png, format="PNG", optimize=False)
            
            # Also export metadata JSON for local Dart composer
            canvases = _collect_stand_canvases(img, reg)
            if canvases:
                meta = {
                    "part_id": part_id,
                    "canvases": canvases,
                }
                with open(out_json, "w", encoding="utf-8") as f:
                    json.dump(meta, f, ensure_ascii=False, indent=2)
            
            print(f"  ✓ part {part_id} → {part_id}.png ({pil.width}x{pil.height})")
            ok += 1
        except Exception as exc:
            print(f"  ✗ part {part_id}: {exc}")
            fail += 1

    return ok, fail


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--client', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--region', default='EMS')
    ap.add_argument('--force', action='store_true')
    args = ap.parse_args()
    ok, fail = extract_character_parts(args.client, args.out, region=args.region, force=args.force)
    print(f'Done: {ok} ok, {fail} fail')
