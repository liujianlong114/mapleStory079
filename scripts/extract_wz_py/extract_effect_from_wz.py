#!/usr/bin/env python3
"""从 ``Effect.wz`` 导出玩家相关动画帧（升级 / 转职 / 物品拾取 / 命中数字）。

输出目录（默认 ``client/assets/sprites/effect/``）结构::

    assets/sprites/effect/
        levelUp.json           # 动画元数据（frames / delays / origins）
        levelUp_0.png
        levelUp_1.png
        ...
        jobChanged_0.png
        ...
        pickUpItem_0.png       # 用 BasicEff/QuestClear 作为近似拾取闪光
        ...
        coolHit.png            # 暴击标记（单帧）
        hit.png                # 普通命中占位（同 coolHit）

用法::

    PYTHONPATH=.cache/wz-python .cache/wz-python/.venv/bin/python \\
        scripts/extract_wz_py/extract_effect_from_wz.py \\
        --client ~/Downloads/冒险岛079/extracted_client [--force]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import Any, Dict, List, Optional, Tuple

from wzpy.canvas import decode_canvas
from wzpy.properties import (
    WzCanvasProperty,
    WzIntProperty,
    WzSubProperty,
    WzVectorProperty,
)
from wzpy.wz_file import WzFile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
DEFAULT_DELAY_MS = 100

# (WZ 文件, WZ 相对路径, 输出名称) 映射 —— 与 079 官方 WZ 实际节点对齐
ANIM_SPECS: List[Tuple[str, str, str]] = [
    ("Effect.wz", "BasicEff.img/LevelUp", "levelUp"),
    ("Effect.wz", "BasicEff.img/JobChanged", "jobChanged"),
    ("Effect.wz", "BasicEff.img/QuestClear", "pickUpItem"),
    ("Effect.wz", "BasicEff.img/CoolHit/cool", "coolHit"),
]

# 单帧数字/命中：将 coolHit 的 canvas 复制一份作为普通 hit 占位（后续可用 NoRed/NoCri 替换）
SINGLE_COPY: List[Tuple[str, str]] = [
    ("coolHit.png", "hit.png"),
]


# ---------------------------------------------------------------------------
# 通用 WZ 导航
# ---------------------------------------------------------------------------
def open_wz_file(client_root: str, fname: str) -> WzFile:
    path = os.path.join(client_root, fname)
    for ver in (79, 80, 83):
        for region in ("EMS", "GMS", "KMS"):
            try:
                wf = WzFile.open(path, region=region, version=ver)
                # 尝试解析第一张 image 以验证密钥正确
                if wf.root.images:
                    first_img = next(iter(wf.root.images.values()))
                    first_img.parse()
                return wf
            except Exception:
                continue
    # 最后再尝试一个默认版本（可能失败），以给出可提示的错误
    return WzFile.open(path, region="EMS", version=79)


def lookup_node(wf: WzFile, path: str):
    """``Effect.wz`` 内的路径形如 ``BasicEff.img/LevelUp``。

    注：``WzImage`` 与 ``WzSubProperty`` 都实现了 ``.get(name)``，但彼此
    不是继承关系，这里用鸭子类型导航。
    """
    parts = [p for p in path.split("/") if p]
    if not parts:
        return None
    first = parts[0]
    img = wf.root.images.get(first)
    if img is None:
        return None
    try:
        img.parse()
    except Exception:
        pass
    node = img
    for sub in parts[1:]:
        if isinstance(node, WzCanvasProperty):
            return node
        if not hasattr(node, "get"):
            return None
        next_node = node.get(sub)
        if next_node is None:
            # 某些节点用数字子节点 + 子 sub，降级：在当前节点的 children 中找数字子节点
            if hasattr(node, "children"):
                for child in node.children():
                    if getattr(child, "name", None) == sub:
                        next_node = child
                        break
        if next_node is None:
            return None
        node = next_node
    return node


# ---------------------------------------------------------------------------
# 帧收集 / 解码
# ---------------------------------------------------------------------------
def _int_of(node: Any, key: str, default: int) -> int:
    if not hasattr(node, "get"):
        return default
    ch = node.get(key)
    if isinstance(ch, WzIntProperty):
        try:
            v = int(ch.value)
            if 0 <= v < 10_000_000:
                return v
        except Exception:
            pass
    return default


def _vec_of(node: Any, key: str) -> Tuple[int, int]:
    if not hasattr(node, "get"):
        return (0, 0)
    ch = node.get(key)
    if isinstance(ch, WzVectorProperty):
        x = int(getattr(ch, "x", 0) or 0)
        y = int(getattr(ch, "y", 0) or 0)
        return (x, y)
    return (0, 0)


def collect_frames(node) -> List[Tuple[int, WzCanvasProperty, int, Tuple[int, int]]]:
    """遍历 node 的数字子节点 ``0, 1, 2, ...``，返回 ``(idx, canvas, delay_ms, origin)``。

    每个数字子节点可以是 ``WzCanvasProperty`` 本身（此时 origin/delay 挂在 canvas 下），
    也可以是一个 ``WzSubProperty``，内部第一个 canvas 子节点就是当前帧。
    """
    out: List[Tuple[int, WzCanvasProperty, int, Tuple[int, int]]] = []
    if node is None:
        return out
    children = list(node.children()) if hasattr(node, "children") else []
    # 按名称的数字排序
    def _name(n) -> str:
        return str(getattr(n, "name", ""))

    numeric = [c for c in children if re.fullmatch(r"\d+", _name(c))]
    numeric.sort(key=lambda c: int(_name(c)))

    for c in numeric:
        idx = int(_name(c))
        canvas: Optional[WzCanvasProperty] = None
        delay_ms = DEFAULT_DELAY_MS
        origin = (0, 0)
        if isinstance(c, WzCanvasProperty):
            canvas = c
            # origin / delay 是 canvas 的兄弟节点，这里简单处理：向上找 canvas 的子属性
            # WzCanvasProperty 本身通常没有 children，origin/delay 挂在同一父节点下
            for sib in children:
                if getattr(sib, "name", None) in ("origin",):
                    origin = _vec_of(node, "origin")
                if getattr(sib, "name", None) in ("delay",):
                    delay_ms = _int_of(node, "delay", DEFAULT_DELAY_MS)
            # 若上面没取到，也看看 canvas 子属性（罕见）
            if hasattr(c, "children"):
                try:
                    for sub in c.children():
                        sn = getattr(sub, "name", None)
                        if sn == "origin":
                            origin = _vec_of(c, "origin")
                        elif sn == "delay":
                            delay_ms = _int_of(c, "delay", DEFAULT_DELAY_MS)
                except Exception:
                    pass
            # 回退：尝试从父节点再取（部分 WZ 把 origin/delay 放在每个帧子 property 下）
            if origin == (0, 0):
                origin = _vec_of(c, "origin")
            if delay_ms == DEFAULT_DELAY_MS:
                delay_ms = _int_of(c, "delay", DEFAULT_DELAY_MS)
        elif isinstance(c, WzSubProperty):
            # 查找 canvas + origin + delay
            delay_ms = _int_of(c, "delay", DEFAULT_DELAY_MS)
            origin = _vec_of(c, "origin")
            for sub in c.children():
                if isinstance(sub, WzCanvasProperty):
                    canvas = sub
                    break
            if canvas is None:
                # 递归一层（有些 WZ 是 ``{idx}/0/canvas``）
                for sub in c.children():
                    if isinstance(sub, WzSubProperty):
                        for ss in sub.children():
                            if isinstance(ss, WzCanvasProperty):
                                canvas = ss
                                break
                    if canvas is not None:
                        break
        if canvas is None:
            continue
        out.append((idx, canvas, delay_ms, origin))
    return out


def save_frames(node, out_dir: str, prefix: str, force: bool) -> Optional[Dict[str, Any]]:
    frames = collect_frames(node)
    if not frames:
        # 尝试：node 自身就是 canvas（例如 CoolHit/cool）
        if isinstance(node, WzCanvasProperty):
            frames = [(0, node, DEFAULT_DELAY_MS, _vec_of(node, "origin"))]
        else:
            print(f"  ✗ {prefix}: 未收集到任何帧")
            return None

    os.makedirs(out_dir, exist_ok=True)
    paths: List[str] = []
    delays: List[int] = []
    origins: List[Dict[str, int]] = []
    width = 0
    height = 0

    for idx, canvas, delay_ms, origin in frames:
        dst = os.path.join(out_dir, f"{prefix}_{idx}.png")
        already = os.path.isfile(dst)
        if already and not force:
            paths.append(dst)
            delays.append(delay_ms)
            origins.append({"x": origin[0], "y": origin[1]})
            # 尝试读取尺寸
            try:
                w = int(getattr(canvas, "width", 0) or 0)
                h = int(getattr(canvas, "height", 0) or 0)
                width = max(width, w)
                height = max(height, h)
            except Exception:
                pass
            continue

        try:
            pil_img = decode_canvas(canvas, region="EMS")
        except Exception as exc:  # noqa: BLE001
            print(f"  ✗ decode failed: {prefix}/{idx} -> {exc}")
            continue
        if pil_img is None or (pil_img.width * pil_img.height) == 0:
            print(f"  ✗ empty canvas: {prefix}/{idx}")
            continue

        pil_img.save(dst, format="PNG", optimize=False)
        paths.append(dst)
        delays.append(delay_ms)
        origins.append({"x": origin[0], "y": origin[1]})
        width = max(width, pil_img.width)
        height = max(height, pil_img.height)

    if not paths:
        print(f"  ✗ {prefix}: 解码全部失败")
        return None

    meta: Dict[str, Any] = {
        "name": prefix,
        "frames": len(paths),
        "delays": delays,
        "origins": origins,
        "maxWidth": width,
        "maxHeight": height,
    }
    meta_path = os.path.join(out_dir, f"{prefix}.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    print(f"  ✓ {prefix}: {len(paths)} frame(s) -> {os.path.basename(meta_path)}")
    return meta


def save_single_canvas(node, out_dir: str, name_no_ext: str, force: bool) -> Optional[Dict[str, Any]]:
    """将一个单独 canvas 节点保存为 ``{name_no_ext}.png``。"""
    if not isinstance(node, WzCanvasProperty):
        # 如果是 subproperty，查找内部第一个 canvas
        if isinstance(node, WzSubProperty):
            for sub in node.children():
                if isinstance(sub, WzCanvasProperty):
                    node = sub
                    break
    if not isinstance(node, WzCanvasProperty):
        return None
    dst = os.path.join(out_dir, f"{name_no_ext}.png")
    if os.path.isfile(dst) and not force:
        return {"name": name_no_ext, "frames": 1, "delays": [DEFAULT_DELAY_MS],
                "origins": [{"x": 0, "y": 0}]}
    try:
        pil_img = decode_canvas(node, region="EMS")
    except Exception:
        return None
    if pil_img is None or pil_img.width * pil_img.height == 0:
        return None
    os.makedirs(out_dir, exist_ok=True)
    pil_img.save(dst, format="PNG", optimize=False)
    print(f"  ✓ {name_no_ext}.png ({pil_img.width}x{pil_img.height})")
    return {"name": name_no_ext, "frames": 1,
            "delays": [DEFAULT_DELAY_MS],
            "origins": [{"x": 0, "y": 0}],
            "width": pil_img.width, "height": pil_img.height}


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--client", required=True, help="079 extracted_client 目录")
    ap.add_argument("--out", default=os.path.join("client", "assets", "sprites", "effect"))
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    out_dir = os.path.join(REPO_ROOT, args.out) if not os.path.isabs(args.out) else args.out
    os.makedirs(out_dir, exist_ok=True)

    # 以 WZ 文件为单位批量打开，避免重复打开 / 解析
    opened: Dict[str, WzFile] = {}
    try:
        for wz_file, wz_path, out_prefix in ANIM_SPECS:
            wf = opened.get(wz_file)
            if wf is None:
                wf = open_wz_file(args.client, wz_file)
                opened[wz_file] = wf
            print(f"[effect] {wz_file}/{wz_path} -> {out_prefix}")
            node = lookup_node(wf, wz_path)
            if node is None:
                print(f"  ✗ 未找到节点: {wz_path}")
                continue
            meta = save_frames(node, out_dir, out_prefix, args.force)
            if meta is None and isinstance(node, WzCanvasProperty):
                save_single_canvas(node, out_dir, out_prefix, args.force)
        # 额外：若 coolHit 导出成功，复制一份到 hit.png
        for src_name, dst_name in SINGLE_COPY:
            src = os.path.join(out_dir, src_name)
            dst = os.path.join(out_dir, dst_name)
            if not os.path.isfile(src):
                continue
            if os.path.isfile(dst) and not args.force:
                continue
            try:
                with open(src, "rb") as fin:
                    data = fin.read()
                with open(dst, "wb") as fout:
                    fout.write(data)
                print(f"  ✓ copy {src_name} -> {dst_name}")
            except Exception as exc:  # noqa: BLE001
                print(f"  ✗ copy failed: {exc}")

        print()
        print("实际文件:")
        for p in sorted(os.listdir(out_dir)):
            print("  -", p)
    finally:
        for wf in opened.values():
            try:
                wf.close()
            except Exception:
                pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
