"""从 Sound.wz / Data/Sound/*.img 提取 BGM。"""

from __future__ import annotations

import os
from typing import List, Optional, Tuple

from wzpy import WzImage, WzKey, detect_region_from_img
from wzpy.properties import WzSoundProperty
from wzpy.wz_file import WzFile

from extract import load_standalone_img, load_wz_img, read_sound_bytes


BGM_JOBS = [
    ("Sound/Bgm00.img", "Bgm00.img", "FloralLife", "audio/00001000.wav"),
    ("Sound/Bgm00.img", "Bgm00.img", "FloralLife", "audio/bgm/florallife.mp3"),
    ("Sound/BgmUI.img", "BgmUI.img", "Title", "audio/title.mp3"),
    ("Sound/BgmUI.img", "BgmUI.img", "Title", "audio/title.wav"),
    ("Sound/UI.img", "UI.img", "CharSelect", "audio/char_select.mp3"),
    ("Sound/UI.img", "UI.img", "CharSelect", "audio/char_select.wav"),
]


def _load_sound_img(client_root: str, data_rel: str, wz_img: str, region: str):
    data_path = os.path.join(client_root, "Data", data_rel.replace("/", os.sep))
    if os.path.isfile(data_path):
        return load_standalone_img(data_path)
    img_name = wz_img if wz_img.endswith(".img") else data_rel.split("/")[-1]
    wz_name = "Sound.wz"
    return load_wz_img(client_root, wz_name, img_name, region)


def extract_bgm(
    client_root: str,
    out_root: str,
    region: str = "EMS",
    force: bool = False,
) -> Tuple[int, int]:
    ok = fail = 0

    for data_rel, wz_img, sound_name, rel_out in BGM_JOBS:
        dst = os.path.join(out_root, rel_out)
        if not force and os.path.isfile(dst) and os.path.getsize(dst) >= 8192:
            ok += 1
            continue
        try:
            img, reg = _load_sound_img(client_root, data_rel, wz_img, region)
            prop = img._root.get(sound_name)
            if not isinstance(prop, WzSoundProperty):
                raise FileNotFoundError(sound_name)
            os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
            with open(dst, "wb") as f:
                f.write(read_sound_bytes(prop))
            print(f"  ✓ {data_rel}/{sound_name} → {rel_out}")
            ok += 1
        except Exception as exc:
            print(f"  ✗ {rel_out}: {exc}")
            fail += 1

    return ok, fail
