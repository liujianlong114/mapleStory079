#!/usr/bin/env python3
"""运行时 CharLook 合成：读取 JSON 外观，输出 stand1 PNG（Phase 1）。"""

from __future__ import annotations

import argparse
import json
import os
import sys

from PIL import Image

from wzpy.character import CharacterRenderer
from wzpy.wz_file import WzFile


def load_wz(client: str, region: str) -> WzFile:
    path = os.path.join(client, "Character.wz")
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region=region, version=ver)
        except Exception:
            continue
    return WzFile.open(path, region=region)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--region", default="EMS")
    ap.add_argument("--pose", default="stand1")
    ap.add_argument("--frame", type=int, default=0)
    ap.add_argument("--scale", type=int, default=3, help="整数倍放大，选角/游戏内更清晰")
    ap.add_argument("--pad", type=int, default=12)
    ap.add_argument("--json", required=True, help="CharLook JSON 文件路径")
    args = ap.parse_args()

    with open(args.json, encoding="utf-8") as f:
        data = json.load(f)

    equip = data.get("equip_ids")
    if not equip:
        equip = []
        body = 2001 if int(data.get("gender", 0)) == 1 else 2000
        head = body + 10000  # 0001200x 与 0000200x 成对（HeavenClient Body.cpp）
        order = [
            body,
            head,
            int(data.get("face", 0)),
            int(data.get("hair", 0)),
        ]
        longcoat = int(data.get("longcoat", 0))
        if longcoat:
            order.append(longcoat)
        else:
            for k in ("top", "bottom"):
                v = int(data.get(k, 0))
                if v:
                    order.append(v)
        for k in ("shoes", "glove", "cap", "cape", "shield", "weapon", "face_acc", "eye_acc", "earring"):
            v = int(data.get(k, 0))
            if v:
                order.append(v)
        seen = set()
        for i in order:
            if i and i not in seen:
                seen.add(i)
                equip.append(f"{i:08d}")

    wz = load_wz(args.client, args.region)
    renderer = CharacterRenderer(wz, region=args.region)
    img = renderer.compose(equip, pose=args.pose, frame=args.frame, flip=False)
    if img.width < 4 or img.height < 4:
        print("empty compose", file=sys.stderr)
        return 1

    scale = max(1, args.scale)
    if scale > 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)

    pad = max(0, args.pad)
    canvas = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    canvas.alpha_composite(img, (pad, pad))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)) or ".", exist_ok=True)
    canvas.save(args.out, format="PNG")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
