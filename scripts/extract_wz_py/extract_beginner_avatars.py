#!/usr/bin/env python3
"""批量导出创角/选角全部组合的 CharacterRenderer.compose 立绘。

与 BeginnerCreationCatalog 一致；官方客户端用 CharLook 叠层，此处预烘焙为 avatars/*.png。
"""

from __future__ import annotations

import argparse
import itertools
import os
from typing import Iterator, List, Tuple

from PIL import Image

from wzpy.character import CharacterRenderer
from wzpy.wz_file import WzFile

MALE_FACES = [20100, 20401, 20402]
MALE_HAIRS = [30030, 30027, 30000]
MALE_TOPS = [1040002, 1040006, 1040010, 1042167]
MALE_BOTTOMS = [1060002, 1060006, 1062115]

FEMALE_FACES = [21002, 21700, 21201]
FEMALE_HAIRS = [31002, 31047, 31057]
FEMALE_TOPS = [1041002, 1041006, 1041010, 1041011, 1042167]
FEMALE_BOTTOMS = [1061002, 1061008, 1062115]

SHOES = [1072001, 1072005, 1072037, 1072038, 1072383]
WEAPONS = [1302000, 1322005, 1312004, 1442079]


def load_wz(client: str, region: str) -> WzFile:
    path = os.path.join(client, "Character.wz")
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region=region, version=ver)
        except Exception:
            continue
    return WzFile.open(path, region=region)


def look_key(gender: int, face: int, hair: int, top: int, bottom: int, shoes: int, weapon: int) -> str:
    return f"{gender}_{face}_{hair}_{top}_{bottom}_{shoes}_{weapon}"


def equip_list(gender: int, face: int, hair: int, top: int, bottom: int, shoes: int, weapon: int) -> List[str]:
    body = 2001 if gender == 1 else 2000
    head = body + 10000
    ids = [body, head, face, hair, top, bottom, shoes]
    if weapon:
        ids.append(weapon)
    return [f"{i:08d}" for i in ids]


def iter_looks(gender: int) -> Iterator[Tuple[int, int, int, int, int, int]]:
    if gender == 0:
        faces, hairs, tops, bottoms = MALE_FACES, MALE_HAIRS, MALE_TOPS, MALE_BOTTOMS
    else:
        faces, hairs, tops, bottoms = FEMALE_FACES, FEMALE_HAIRS, FEMALE_TOPS, FEMALE_BOTTOMS
    for face, hair, top, bottom, shoe, weapon in itertools.product(
        faces, hairs, tops, bottoms, SHOES, WEAPONS
    ):
        yield face, hair, top, bottom, shoe, weapon


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", default="client/assets/characters/avatars")
    ap.add_argument("--region", default="EMS")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    wz = load_wz(args.client, args.region)
    renderer = CharacterRenderer(wz, region=args.region)
    os.makedirs(args.out, exist_ok=True)

    ok = skip = fail = 0
    for gender in (0, 1):
        for face, hair, top, bottom, shoes, weapon in iter_looks(gender):
            key = look_key(gender, face, hair, top, bottom, shoes, weapon)
            out_path = os.path.join(args.out, f"{key}.png")
            if not args.force and os.path.isfile(out_path) and os.path.getsize(out_path) >= 512:
                skip += 1
                continue
            try:
                equip = equip_list(gender, face, hair, top, bottom, shoes, weapon)
                img = renderer.compose(equip, pose="stand1", flip=False)
                if img.width < 8 or img.height < 8:
                    raise ValueError("empty")
                canvas = Image.new("RGBA", (img.width + 16, img.height + 16), (0, 0, 0, 0))
                canvas.alpha_composite(img, (8, 8))
                canvas.save(out_path, format="PNG")
                ok += 1
                if ok % 200 == 0:
                    print(f"  … {ok} exported")
            except Exception as exc:
                fail += 1
                if fail <= 20:
                    print(f"  ✗ {key}: {exc}")

    print(f"✓ 创角立绘: 新增 {ok} | 跳过 {skip} | 失败 {fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
