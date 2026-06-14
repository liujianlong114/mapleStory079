"""导出选角/创角用完整角色立绘 PNG（CharacterRenderer.compose）。"""

from __future__ import annotations

import os
from typing import List, Tuple

from PIL import Image

from wzpy.character import CharacterRenderer
from wzpy.wz_file import WzFile

# 079 CharLoginHandler 白名单 + 默认新手装
LOOKS: List[Tuple[int, int, int, int, int, int, int]] = [
    # gender, face, hair, top, bottom, shoes, weapon
    (0, 20100, 30000, 1040002, 1060002, 1072001, 1302000),  # seed 冒险者一号
    (1, 20100, 30000, 1041002, 1061002, 1072001, 1302000),  # 女号同脸发（DB）
    (1, 20100, 30000, 1041002, 1061002, 1072001, 0),
    (0, 20100, 30000, 1040002, 1060002, 1072001, 0),       # 剑士试炼等男号
    (1, 21002, 31002, 1041002, 1061002, 1072001, 1302000),  # seed 见习新手
    (0, 20401, 30027, 1040006, 1060006, 1072005, 1322005),
    (0, 20402, 30000, 1040010, 1060002, 1072037, 1312004),
    (1, 21002, 31002, 1041002, 1061002, 1072001, 1302000),
    (1, 21700, 31047, 1041006, 1061008, 1072005, 1322005),
    (1, 21201, 31057, 1041010, 1061002, 1072038, 1312004),
    (1, 21002, 31002, 1041011, 1061002, 1072001, 0),
]


def _load_wz(client_root: str, region: str) -> WzFile:
    path = os.path.join(client_root, "Character.wz")
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region=region, version=ver)
        except Exception:
            continue
    return WzFile.open(path, region=region)


def look_key(gender: int, face: int, hair: int, top: int, bottom: int, shoes: int, weapon: int) -> str:
    return f"{gender}_{face}_{hair}_{top}_{bottom}_{shoes}_{weapon}"


def _equip_id(n: int) -> str:
    return f"{n:08d}"


def extract_avatars(client_root: str, out_dir: str, region: str = "EMS", force: bool = False) -> Tuple[int, int]:
    os.makedirs(out_dir, exist_ok=True)
    wz = _load_wz(client_root, region)
    renderer = CharacterRenderer(wz, region=region)
    ok = fail = 0
    for gender, face, hair, top, bottom, shoes, weapon in LOOKS:
        body = 2001 if gender == 1 else 2000
        equip: List[str] = [
            _equip_id(body),
            _equip_id(face),
            _equip_id(hair),
            _equip_id(top),
            _equip_id(bottom),
            _equip_id(shoes),
        ]
        if weapon:
            equip.append(_equip_id(weapon))
        key = look_key(gender, face, hair, top, bottom, shoes, weapon)
        out_path = os.path.join(out_dir, f"{key}.png")
        if not force and os.path.isfile(out_path) and os.path.getsize(out_path) >= 2048:
            ok += 1
            continue
        try:
            img = renderer.compose(equip, pose="stand1", flip=False)
            if img.width < 8 or img.height < 8:
                raise ValueError("empty composite")
            pad = 8
            canvas = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
            canvas.alpha_composite(img, (pad, pad))
            canvas.save(out_path, format="PNG")
            print(f"  ✓ avatar {key} ({img.width}x{img.height})")
            ok += 1
        except Exception as exc:
            print(f"  ✗ avatar {key}: {exc}")
            fail += 1
    return ok, fail
