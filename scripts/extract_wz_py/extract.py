#!/usr/bin/env python3
"""从 MapleStory 079 客户端提取登录/选角 UI 与 BGM。

支持两种客户端布局：
  1. 经典 Data/*.img（如怀旧岛 MAX3 客户端 Data/UI/Login.img）
  2. 二进制 WZ（如 冒险岛079 解压后的 UI.wz / Sound.wz / Map.wz）

依赖 wz-python（Leonana69/wz-python），由 setup_maple_wz.sh 自动克隆到 .cache/wz-python。

用法:
  python scripts/extract_wz_py/extract.py --client /path/to/client [--out client/assets] [--force]
  MAPLE_WZ_ROOT=/path/to/client FORCE=1 python scripts/extract_wz_py/extract.py
"""

from __future__ import annotations

import argparse
import io
import os
import sys
from typing import Callable, Iterable, List, Optional, Tuple, Union

# wz-python 由 wrapper 注入 PYTHONPATH
from wzpy import WzImage, WzKey, detect_region_from_img
from wzpy.canvas import decode_canvas
from wzpy.properties import WzCanvasProperty, WzSoundProperty, WzSubProperty
from wzpy.wz_file import WzFile

Node = Union[WzImage, WzSubProperty, WzCanvasProperty, WzSoundProperty]

MIN_REAL_PNG = 2048
MIN_REAL_SOUND = 8192


def is_data_client(root: str) -> bool:
    return os.path.isfile(os.path.join(root, "Data", "UI", "Login.img"))


def is_binary_wz(root: str) -> bool:
    return os.path.isfile(os.path.join(root, "UI.wz")) and os.path.isfile(
        os.path.join(root, "Sound.wz")
    )


def client_data_root(root: str) -> str:
    if is_data_client(root):
        return os.path.join(root, "Data")
    return root


def is_real_asset(path: str, kind: str) -> bool:
    try:
        size = os.path.getsize(path)
    except OSError:
        return False
    if kind == "png":
        return size >= MIN_REAL_PNG
    if kind == "sound":
        return size >= MIN_REAL_SOUND
    return size > 1024


def read_sound_bytes(sound: WzSoundProperty) -> bytes:
    if getattr(sound, "_data", None) is not None:
        return sound._data
    r = sound._wz_image.wz_file.reader
    keep = r.position
    r.seek(sound._data_offset)
    data = r.read(sound._data_length)
    r.seek(keep)
    return data


def resolve_prop(root: WzSubProperty, parts: Iterable[str]) -> Optional[Node]:
    node: Optional[Node] = root
    for part in parts:
        if node is None:
            return None
        if isinstance(node, WzCanvasProperty):
            break
        if not isinstance(node, WzSubProperty):
            return None
        node = node.get(part)
    if isinstance(node, WzCanvasProperty):
        return node
    if isinstance(node, WzSubProperty):
        for child in node.children():
            if isinstance(child, WzCanvasProperty):
                return child
    return node


def load_standalone_img(path: str) -> Tuple[WzImage, str]:
    data = open(path, "rb").read()
    region = detect_region_from_img(data) or "EMS"
    img = WzImage.from_bytes(data, key=WzKey.for_region(region), name=os.path.basename(path))
    img.parse()
    return img, region


def open_wz_file(client_root: str, wz_name: str, region: str) -> WzFile:
    path = os.path.join(client_root, wz_name)
    for ver in (79, 80, 83):
        try:
            wf = WzFile.open(path, region=region, version=ver)
            return wf
        except Exception:
            continue
    return WzFile.open(path, region=region)


def load_wz_img(client_root: str, wz_name: str, img_path: str, region: str) -> Tuple[WzImage, str]:
    wf = open_wz_file(client_root, wz_name, region)
    node = wf.root.get(img_path)
    if node is None:
        raise FileNotFoundError(f"{wz_name}:{img_path}")
    node.parse()
    return node, region


class Source:
    def __init__(self, client_root: str, region: str = "EMS"):
        self.client_root = client_root
        self.data_root = client_data_root(client_root)
        self.region = region
        self._data = is_data_client(client_root)
        self._wz = is_binary_wz(client_root)

    def load_img(self, spec: Tuple[str, ...]) -> Tuple[WzImage, str, str]:
        """spec: (relative .img path under Data/) or (WZ file, path in WZ)."""
        if self._data and not spec[0].endswith(".wz"):
            rel = spec[0]
            path = os.path.join(self.data_root, rel)
            img, region = load_standalone_img(path)
            return img, region, rel

        if self._wz:
            wz_name, img_path = spec[0], spec[1]
            img, region = load_wz_img(self.client_root, wz_name, img_path, self.region)
            return img, region, f"{wz_name}/{img_path}"

        raise RuntimeError(f"无法加载: {spec}")


def save_canvas(canvas: WzCanvasProperty, region: str, out_path: str) -> None:
    img = decode_canvas(canvas, region=region)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, format="PNG", optimize=False)


def save_sound(sound: WzSoundProperty, out_path: str) -> None:
    data = read_sound_bytes(sound)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(data)


def extract_jobs() -> List[dict]:
    """与 scripts/extract_wz_login/main.go 对齐的导出任务。"""
    jobs: List[dict] = []

    def png(
        sources: List[Tuple[str, ...]],
        out: str,
        inner: Tuple[str, ...],
        optional: bool = False,
    ) -> None:
        jobs.append({"kind": "png", "sources": sources, "out": out, "path": inner, "optional": optional})

    def snd(
        sources: List[Tuple[str, ...]],
        out: str,
        inner: Tuple[str, ...],
        optional: bool = False,
    ) -> None:
        jobs.append({"kind": "sound", "sources": sources, "out": out, "path": inner, "optional": optional})

    ui_img = [("UI/Login.img",), ("UI.wz", "Login.img")]
    map_obj = [("Map/Obj/login.img",), ("Map.wz", "Obj/login.img")]
    map_back = [("Map/Back/login.img",), ("Map.wz", "Back/login.img")]
    bgm_ui = [("Sound/BgmUI.img",), ("Sound.wz", "BgmUI.img")]
    sound_ui = [("Sound/UI.img",), ("Sound.wz", "UI.img")]

    snd(bgm_ui, "audio/title.mp3", ("Title",))
    snd(bgm_ui, "audio/title.wav", ("Title",), optional=True)
    snd(sound_ui, "audio/char_select.mp3", ("CharSelect",))
    snd(sound_ui, "audio/char_select.wav", ("CharSelect",), optional=True)
    snd(bgm_ui, "audio/char_select.mp3", ("WCSelect",), optional=True)

    png(ui_img, "images/ui/login/btn_login_normal.png", ("Title", "BtLogin", "normal", "0"))
    png(ui_img, "images/ui/login/btn_login_over.png", ("Title", "BtLogin", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_login_pressed.png", ("Title", "BtLogin", "pressed", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_quit_normal.png", ("Title", "BtQuit", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_quit_over.png", ("Title", "BtQuit", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_quit_pressed.png", ("Title", "BtQuit", "pressed", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_select_normal.png", ("CharSelect", "BtSelect", "normal", "0"))
    png(ui_img, "images/ui/login/btn_select_over.png", ("CharSelect", "BtSelect", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_select_pressed.png", ("CharSelect", "BtSelect", "pressed", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_new_normal.png", ("CharSelect", "BtNew", "normal", "0"))
    png(ui_img, "images/ui/login/btn_new_over.png", ("CharSelect", "BtNew", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_delete_normal.png", ("CharSelect", "BtDelete", "normal", "0"))
    png(ui_img, "images/ui/login/btn_delete_over.png", ("CharSelect", "BtDelete", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_start_normal.png", ("Common", "BtStart", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_ok_normal.png", ("Common", "BtOK", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_cancel_normal.png", ("Common", "BtCancel", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/newchar_charset.png", ("NewChar", "charSet"), optional=True)
    png(ui_img, "images/ui/login/newchar_charname.png", ("NewChar", "charName"), optional=True)
    png(ui_img, "images/ui/login/btn_yes_normal.png", ("NewChar", "BtYes", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_yes_over.png", ("NewChar", "BtYes", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_no_normal.png", ("NewChar", "BtNo", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_no_over.png", ("NewChar", "BtNo", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_left_normal.png", ("NewChar", "BtLeft", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_right_normal.png", ("NewChar", "BtRight", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/newchar_dice_0.png", ("NewChar", "dice", "0"), optional=True)
    png(ui_img, "images/ui/login/newchar_scroll_open.png", ("NewChar", "scroll", "0", "1"), optional=True)
    png(ui_img, "images/ui/login/newchar_tab_normal.png", ("NewChar", "avatarSel", "0", "normal"), optional=True)
    png(ui_img, "images/ui/login/newchar_tab_sel.png", ("NewChar", "avatarSel", "1", "normal"), optional=True)
    png(ui_img, "images/ui/login/btn_page_l.png", ("CharSelect", "pageL", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_page_r.png", ("CharSelect", "pageR", "normal", "0"), optional=True)

    png(ui_img, "images/ui/login/panel_backgrnd.png", ("Title", "Gender", "Backgrnd"))
    png(ui_img, "images/ui/login/worldselect_chback.png", ("WorldSelect", "chBackgrn"), optional=True)
    png(ui_img, "images/ui/login/worldselect_popup.png", ("WorldSelect", "Popup"), optional=True)
    png(ui_img, "images/ui/login/btn_world_0_normal.png", ("WorldSelect", "BtWorld", "0", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_world_0_over.png", ("WorldSelect", "BtWorld", "0", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_world_0_pressed.png", ("WorldSelect", "BtWorld", "0", "pressed", "0"), optional=True)
    # WorldSelect 确认/取消（覆盖 NewChar 尺寸相同的 BtYes/BtNo）
    png(ui_img, "images/ui/login/btn_yes_normal.png", ("WorldSelect", "BtYes", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_yes_over.png", ("WorldSelect", "BtYes", "mouseOver", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_no_normal.png", ("WorldSelect", "BtNo", "normal", "0"), optional=True)
    png(ui_img, "images/ui/login/btn_no_over.png", ("WorldSelect", "BtNo", "mouseOver", "0"), optional=True)

    png(map_obj, "images/ui/login/logo_0.png", ("Title", "logo", "0"))
    png(map_obj, "images/ui/login/logo_1.png", ("Title", "logo", "1"), optional=True)
    png(map_obj, "images/ui/login/title_signboard.png", ("Title", "signboard", "0"), optional=True)
    png(map_obj, "images/ui/login/slot_board.png", ("CharSelect", "signboard", "0"))
    png(map_obj, "images/ui/login/charselect_banner.png", ("CharSelect", "signboard", "1"), optional=True)
    png(map_obj, "images/ui/login/pedestal.png", ("CharSelect", "character", "0"), optional=True)

    for i in range(38):
        png(
            map_back,
            f"images/ui/login/back/{i:02d}.png",
            ("back", str(i)),
            optional=True,
        )

    return jobs


def run_extract(client: str, out_dir: str, force: bool, region: str) -> int:
    if not is_data_client(client) and not is_binary_wz(client):
        print(f"❌ 未识别的客户端目录: {client}")
        print("   需要 Data/UI/Login.img 或 UI.wz + Sound.wz")
        return 1

    mode = "Data/*.img" if is_data_client(client) else "二进制 WZ"
    print(f"ℹ️  客户端: {client} ({mode})")

    src = Source(client, region=region)
    ok = skip = fail = 0

    for job in extract_jobs():
        dst = os.path.join(out_dir, job["out"])
        if not force and is_real_asset(dst, job["kind"]):
            skip += 1
            continue

        done = False
        last_err: Optional[Exception] = None
        for spec in job["sources"]:
            try:
                img, reg, label = src.load_img(spec)
                prop = resolve_prop(img._root, job["path"])
                if prop is None:
                    raise FileNotFoundError(f"路径不存在: {'/'.join(job['path'])}")

                if job["kind"] == "png":
                    if not isinstance(prop, WzCanvasProperty):
                        raise TypeError(f"非 Canvas: {type(prop)}")
                    save_canvas(prop, reg, dst)
                else:
                    if not isinstance(prop, WzSoundProperty):
                        raise TypeError(f"非 Sound: {type(prop)}")
                    save_sound(prop, dst)

                print(f"  ✓ {label}/{'/'.join(job['path'])} → {job['out']}")
                ok += 1
                done = True
                break
            except Exception as exc:
                last_err = exc

        if done:
            continue
        if job.get("optional"):
            skip += 1
            continue
        print(f"  ✗ {job['out']}: {last_err}")
        fail += 1

    print(f"\n提取完成: 成功 {ok} | 跳过 {skip} | 失败 {fail}")
    if ok > 0:
        print("请运行: go run scripts/build_login_scene/main.go --force")
    return 1 if fail > 0 and ok == 0 else 0


def main() -> None:
    parser = argparse.ArgumentParser(description="从 079 客户端提取登录资源 (wz-python)")
    parser.add_argument(
        "--client",
        default=os.environ.get("MAPLE_WZ_ROOT", ""),
        help="客户端根目录（含 Data/ 或 *.wz）",
    )
    parser.add_argument("--out", default="client/assets", help="输出目录")
    parser.add_argument("--force", action="store_true", help="覆盖已有占位资源")
    parser.add_argument(
        "--region",
        default=os.environ.get("MAPLE_WZ_REGION", "EMS"),
        help="WZ 区域密钥 (私服/CMS 通常 EMS)",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="额外提取角色部件 + 地图 BGM",
    )
    parser.add_argument("--mobs-npcs", action="store_true", help="提取 Mob/Npc 游戏精灵")
    parser.add_argument("--all-mobs", action="store_true", help="提取全部 Mob/Npc（配合 --mobs-npcs）")
    args = parser.parse_args()

    if not args.client:
        print("❌ 请指定 --client 或 MAPLE_WZ_ROOT")
        sys.exit(1)

    force = args.force or os.environ.get("FORCE", "") in ("1", "true")
    client = os.path.abspath(args.client)
    code = run_extract(client, args.out, force, args.region)

    if args.full or os.environ.get("EXTRACT_FULL", "") in ("1", "true"):
        print("\n==> 角色部件 (Character)")
        from extract_parts import extract_character_parts

        pok, pfail = extract_character_parts(
            client, os.path.join(args.out, "characters/parts"), args.region, force
        )
        print(f"部件: 成功 {pok} | 失败 {pfail}")

        print("\n==> 地图/登录 BGM")
        from extract_bgm import extract_bgm

        bok, bfail = extract_bgm(client, args.out, args.region, force)
        print(f"BGM: 成功 {bok} | 失败 {bfail}")

        print("\n==> 角色立绘 (CharacterRenderer.compose)")
        from extract_avatars import extract_avatars

        aok, afail = extract_avatars(
            client, os.path.join(args.out, "characters/avatars"), args.region, force
        )
        print(f"立绘: 成功 {aok} | 失败 {afail}")

        print("\n==> 游戏精灵 Mob/Npc")
        from extract_mobs_npcs import run_extract_mobs_npcs

        mok, mfail = run_extract_mobs_npcs(
            client, args.out, args.region, extract_all=True, force=force,
        )
        print(f"Mob/Npc: 成功 {mok} | 失败 {mfail}")
        if pfail > 0 or bfail > 0 or afail > 0:
            code = max(code, 0)  # 部分失败仍继续

    if args.mobs_npcs or os.environ.get("EXTRACT_MOBS", "") in ("1", "true"):
        print("\n==> 游戏精灵 Mob/Npc")
        from extract_mobs_npcs import run_extract_mobs_npcs

        mok, mfail = run_extract_mobs_npcs(
            client, args.out, args.region,
            extract_all=args.all_mobs or os.environ.get("EXTRACT_ALL_MOBS", "") in ("1", "true"),
            force=force,
        )
        print(f"Mob/Npc: 成功 {mok} | 失败 {mfail}")

    sys.exit(code)


if __name__ == "__main__":
    main()
