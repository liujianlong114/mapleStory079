"""从 Mob.wz / Npc.wz 导出游戏内精灵 PNG（stand + move 条带）。

用法:
  python scripts/extract_wz_py/extract_mobs_npcs.py --client ../mapleStory079-external/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制 [--out client/assets] [--all]
"""

from __future__ import annotations

import argparse
import os
import re
from typing import Iterable, List, Optional, Tuple

from PIL import Image

from wzpy.canvas import decode_canvas
from wzpy.properties import WzCanvasProperty, WzSubProperty
from wzpy.wz_file import WzFile

MIN_REAL_PNG = 400

# 彩虹村 / 新手地图 + seed NPC + 默认刷怪池
PRIORITY_MOBS = {
    100100, 100101, 100102, 100200, 100400, 100800,
    110100, 120100, 130100, 100401, 100700, 100900, 101000, 109000,
    130101, 2100100, 2100101, 1210100, 1210101,
}

PRIORITY_NPCS = {
    12000, 1012112, 1012114, 10000, 2000, 12101,
    1012008, 1012101, 1032105, 2040010, 1090000,
    1072008, 1072009, 1011001,
}


def open_wz(client_root: str, name: str, region: str) -> WzFile:
    path = os.path.join(client_root, name)
    for ver in (79, 80, 83):
        try:
            return WzFile.open(path, region=region, version=ver)
        except Exception:
            continue
    return WzFile.open(path, region=region)


def mob_img_key(mob_id: int) -> str:
    return f"{mob_id:07d}.img"


def npc_img_key(npc_id: int) -> str:
    return f"{npc_id:07d}.img"


def first_canvas(node: Optional[WzSubProperty], frame: str = "0") -> Optional[WzCanvasProperty]:
    if node is None:
        return None
    c = node.get(frame)
    if isinstance(c, WzCanvasProperty):
        return c
    for child in node.children():
        if isinstance(child, WzCanvasProperty):
            return child
    return None


def collect_frames(pose: Optional[WzSubProperty], max_frames: int = 12) -> List[WzCanvasProperty]:
    if pose is None:
        return []
    out: List[WzCanvasProperty] = []
    for i in range(max_frames):
        c = pose.get(str(i))
        if isinstance(c, WzCanvasProperty):
            out.append(c)
    if out:
        return out
    for child in pose.children():
        if isinstance(child, WzCanvasProperty):
            out.append(child)
    return out


def save_strip(frames: List[Image.Image], out_path: str) -> None:
    if not frames:
        return
    h = max(f.height for f in frames)
    w = sum(f.width for f in frames)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = 0
    for f in frames:
        canvas.alpha_composite(f, (x, (h - f.height) // 2))
        x += f.width
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path, format="PNG")


def save_canvas(canvas: WzCanvasProperty, region: str, out_path: str) -> bool:
    img = decode_canvas(canvas, region=region)
    if img.width < 4 or img.height < 4:
        return False
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, format="PNG")
    return os.path.getsize(out_path) >= MIN_REAL_PNG


def parse_img_id(name: str) -> Optional[int]:
    m = re.match(r"(\d+)\.img$", name)
    if not m:
        return None
    return int(m.group(1))


def extract_mob(wf: WzFile, mob_id: int, out_mob: str, region: str, force: bool) -> bool:
    key = mob_img_key(mob_id)
    img = wf.root.get(key)
    if img is None:
        return False
    img.parse()
    stand_path = os.path.join(out_mob, f"{mob_id}.png")
    move_path = os.path.join(out_mob, f"{mob_id}_move.png")
    if not force and os.path.isfile(stand_path) and os.path.getsize(stand_path) >= MIN_REAL_PNG:
        return True
    stand = first_canvas(img.get("stand"))
    if stand is None:
        for alt in ("fly", "hit1", "regen"):
            stand = first_canvas(img.get(alt))
            if stand:
                break
    if stand is None:
        return False
    if not save_canvas(stand, region, stand_path):
        return False
    move_pose = img.get("move") or img.get("fly")
    move_frames = collect_frames(move_pose)
    if move_frames:
        pil_frames = [decode_canvas(c, region=region) for c in move_frames]
        save_strip(pil_frames, move_path)
    return True


def extract_npc(wf: WzFile, npc_id: int, out_npc: str, region: str, force: bool) -> bool:
    key = npc_img_key(npc_id)
    img = wf.root.get(key)
    if img is None:
        return False
    img.parse()
    out_path = os.path.join(out_npc, f"{npc_id}.png")
    if not force and os.path.isfile(out_path) and os.path.getsize(out_path) >= MIN_REAL_PNG:
        return True
    stand = first_canvas(img.get("stand"))
    if stand is None:
        for alt in ("say", "eye", "blink", "info"):
            stand = first_canvas(img.get(alt))
            if stand:
                break
    if stand is None:
        return False
    return save_canvas(stand, region, out_path)


def all_mob_ids(wf: WzFile) -> List[int]:
    ids: List[int] = []
    for name in wf.root.images:
        mid = parse_img_id(name)
        if mid is not None:
            ids.append(mid)
    return sorted(set(ids))


def all_npc_ids(wf: WzFile) -> List[int]:
    return all_mob_ids(wf)


def run_extract_mobs_npcs(
    client_root: str,
    out_dir: str,
    region: str = "EMS",
    extract_all: bool = False,
    force: bool = False,
) -> Tuple[int, int]:
    out_mob = os.path.join(out_dir, "sprites", "mob")
    out_npc = os.path.join(out_dir, "sprites", "npc")
    os.makedirs(out_mob, exist_ok=True)
    os.makedirs(out_npc, exist_ok=True)

    mob_wf = open_wz(client_root, "Mob.wz", region)
    npc_wf = open_wz(client_root, "Npc.wz", region)

    mob_ids = all_mob_ids(mob_wf) if extract_all else sorted(PRIORITY_MOBS)
    npc_ids = all_npc_ids(npc_wf) if extract_all else sorted(PRIORITY_NPCS)

    mob_ok = mob_fail = 0
    for mid in mob_ids:
        try:
            if extract_mob(mob_wf, mid, out_mob, region, force):
                mob_ok += 1
            else:
                mob_fail += 1
        except Exception:
            mob_fail += 1

    npc_ok = npc_fail = 0
    for nid in npc_ids:
        try:
            if extract_npc(npc_wf, nid, out_npc, region, force):
                npc_ok += 1
            else:
                npc_fail += 1
        except Exception:
            npc_fail += 1

    print(f"✓ Mob {mob_ok}/{len(mob_ids)}  Npc {npc_ok}/{len(npc_ids)}")
    return mob_ok + npc_ok, mob_fail + npc_fail


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True, help="客户端根目录（含 Mob.wz）")
    ap.add_argument("--out", default="client/assets", help="输出 assets 根")
    ap.add_argument("--region", default=os.environ.get("MAPLE_WZ_REGION", "EMS"))
    ap.add_argument("--all", action="store_true", help="导出全部 Mob/Npc（较慢）")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    run_extract_mobs_npcs(
        os.path.abspath(args.client),
        args.out,
        args.region,
        extract_all=args.all,
        force=args.force or os.environ.get("FORCE", "") in ("1", "true"),
    )


if __name__ == "__main__":
    main()
