#!/usr/bin/env python3
"""批量导出新手地图链 + maplife。

- 地图 JSON: client/assets/maps/{mapId}.json
- tile/obj/back PNG: client/assets/maps/{tiles,obj,back}/
- maplife: data/maplife/{mapId}.json 与 client/assets/maplife/{mapId}.json

用法：
  PYTHONPATH=.cache/wz-python .cache/wz-python/.venv/bin/python \
    scripts/extract_wz_py/batch_export_novice_island.py \
    --client ~/Downloads/冒险岛079/extracted_client \
    --force
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from typing import List, Tuple

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))

# (WZ img 名不含 .img, 本项目 mapId, 地图中文名)
MAPS: List[Tuple[str, int, str]] = [
    ("000010000", 1000000, "彩虹村"),
    ("000020000", 20000, "蘑菇森林路径"),
    ("000030000", 30000, "蘑菇森林深处"),
    ("001000000", 100000000, "射手村"),
    ("001010000", 101000000, "魔法密林"),
]


def run(cmd: List[str]) -> int:
    print(f"\n>>> {' '.join(cmd)}")
    rc = subprocess.call(cmd, cwd=REPO_ROOT)
    return rc


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True)
    ap.add_argument("--back-client", default="")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only-life", action="store_true", help="只刷新 maplife")
    args = ap.parse_args()

    venv_py = os.path.join(REPO_ROOT, ".cache", "wz-python", ".venv", "bin", "python")
    map_script = os.path.join(SCRIPT_DIR, "export_map_from_wz.py")
    life_script = os.path.join(SCRIPT_DIR, "extract_maplife_from_wz.py")

    os.chdir(REPO_ROOT)

    ok_count = 0
    for wz_img, map_id, name in MAPS:
        if not args.only_life:
            cmd = [venv_py, map_script, "--client", args.client,
                   "--map", wz_img, "--map-id", str(map_id), "--name", name]
            if args.back_client:
                cmd += ["--back-client", args.back_client]
            if args.force:
                cmd += ["--force"]
            if run(cmd) != 0:
                print(f"  ✗ map export failed for {map_id}")
                continue
        cmd = [venv_py, life_script, "--client", args.client,
               "--map", wz_img, "--map-id", str(map_id)]
        if args.force:
            cmd += ["--force"]
        if run(cmd) != 0:
            print(f"  ✗ life export failed for {map_id}")
            continue
        ok_count += 1

    print(f"\n=== 共处理 {ok_count}/{len(MAPS)} 张地图 ===")
    return 0 if ok_count == len(MAPS) else 1


if __name__ == "__main__":
    raise SystemExit(main())
