#!/usr/bin/env python3
"""导出玩家 walk1/stand1 动画条带 PNG → client/assets/sprites/player/

用法:
  PYTHONPATH=.cache/wz-python .cache/wz-python/.venv/bin/python \\
    scripts/extract_wz_py/extract_player_anim.py \\
    --client ~/GolandProjects/mapleStory079-external/00-官方客户端-…/extracted_client
"""

from __future__ import annotations

import argparse
import os
from typing import List, Tuple

from PIL import Image

from wzpy.character import CharacterRenderer
from wzpy.wz_file import WzFile

# 与 extract_avatars.py LOOKS 一致 + 法师女角常见装
LOOKS: List[Tuple[int, int, int, int, int, int, int, str]] = [
    # gender, face, hair, top, bottom, shoes, weapon, tag
    (0, 20100, 30000, 1040002, 1060002, 1072001, 1302000, "beginner_m"),
    (1, 21002, 31002, 1041002, 1061002, 1072001, 1302000, "beginner_f"),
    (1, 21700, 31047, 1041006, 1061008, 1072005, 1322005, "mage_f"),
    (0, 20401, 30027, 1040006, 1060006, 1072005, 1322005, "warrior_m"),
]


def load_wz(client: str, region: str) -> WzFile:
    path = os.path.join(client, "Character.wz")
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region=region, version=ver)
        except Exception:
            continue
    return WzFile.open(path, region=region)


def equip_list(gender: int, face: int, hair: int, top: int, bottom: int, shoes: int, weapon: int) -> List[str]:
    body = 2001 if gender == 1 else 2000
    head = body + 10000
    ids = [body, head, face, hair, top, bottom, shoes]
    if weapon:
        ids.append(weapon)
    return [f"{i:08d}" for i in ids]


def save_strip(frames: List[Image.Image], out_path: str) -> None:
    if not frames:
        raise ValueError("empty frames")
    h = max(f.height for f in frames)
    w = sum(f.width for f in frames)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = 0
    widths: List[int] = []
    for f in frames:
        canvas.alpha_composite(f, (x, h - f.height))
        widths.append(f.width)
        x += f.width
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path, format="PNG")
    # 不等宽帧 manifest（客户端按真实宽度切条带，禁止等分）
    manifest_path = out_path.replace(".png", "_manifest.json")
    pose = "walk1" if "walk1" in out_path else "stand1"
    step = 0.18 if pose == "walk1" else 0.5
    with open(manifest_path, "w", encoding="utf-8") as mf:
        import json

        json.dump(
            {
                "pose": pose,
                "frames": len(widths),
                "widths": widths,
                "height": h,
                "stepTime": step,
                "anchor": "feet",  # CharacterRenderer 底对齐合成
            },
            mf,
            indent=2,
        )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", default="client/assets/sprites/player")
    ap.add_argument("--region", default="EMS")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    wz = load_wz(args.client, args.region)
    renderer = CharacterRenderer(wz, region=args.region)
    ok = fail = 0

    for gender, face, hair, top, bottom, shoes, weapon, tag in LOOKS:
        equip = equip_list(gender, face, hair, top, bottom, shoes, weapon)
        key = f"{gender}_{face}_{hair}_{top}_{bottom}_{shoes}_{weapon}"
        for pose in ("stand1", "walk1"):
            out = os.path.join(args.out, f"{key}_{pose}.png")
            if not args.force and os.path.isfile(out) and os.path.getsize(out) >= 800:
                ok += 1
                continue
            try:
                frames = renderer.compose_animation(equip, pose=pose, flip=False)
                if len(frames) < 1:
                    raise ValueError("no frames")
                save_strip(frames, out)
                print(f"  ✓ {tag} {pose} → {os.path.basename(out)} ({len(frames)} frames)")
                ok += 1
            except Exception as exc:
                print(f"  ✗ {tag} {pose}: {exc}")
                fail += 1

    print(f"\n玩家动画: 成功 {ok} | 失败 {fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
