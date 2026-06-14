#!/usr/bin/env bash
# 扫描外部参考目录下各开源仓库是否含可提取的游戏贴图/音乐（非 XML 元数据）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"
EX="$(maple_external_root)"

echo "=== 外部参考资源扫描 ($EX) ==="
echo ""

for repo in "$EX"/*/; do
  name="$(basename "$repo")"
  [[ "$name" == "OPEN_SOURCE_RESOURCES.md" ]] && continue
  [[ ! -d "$repo" ]] && continue

  png=$(find "$repo" -type f -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
  mp3=$(find "$repo" -type f -name '*.mp3' 2>/dev/null | wc -l | tr -d ' ')
  wav=$(find "$repo" -type f -name '*.wav' 2>/dev/null | wc -l | tr -d ' ')
  wz_bin=0
  if [[ -f "$repo/wz/Base.wz" ]]; then wz_bin=1; fi
  if [[ -f "$repo/Base.wz" ]]; then wz_bin=1; fi
  wz_xml=0
  if [[ -d "$repo/wz/Base.wz" ]]; then wz_xml=1; fi

  big_png=$(find "$repo" -type f -name '*.png' -size +20k 2>/dev/null | wc -l | tr -d ' ')

  status="❌ 无可用资源"
  if [[ "$wz_bin" -eq 1 ]]; then
    status="✅ 含二进制 Base.wz（可 wzexplorer 提取）"
  elif [[ "$mp3" -gt 0 ]] || [[ "$big_png" -gt 50 ]]; then
    status="⚠️  含部分 PNG/MP3，需人工筛选"
  elif [[ "$wz_xml" -eq 1 ]]; then
    status="❌ WZ 仅为 XML 目录（无像素/音频数据）"
  fi

  printf "%-28s png=%4s mp3=%3s wav=%3s big_png=%4s  %s\n" "$name" "$png" "$mp3" "$wav" "$big_png" "$status"
done

echo ""
echo "说明：私服 GitHub 仓库的 wz/ 几乎都是 HaRepacker「Private Server」XML 导出，"
echo "canvas/sound 节点只有宽高或名称，无法还原 PNG/MP3。"
echo "真实资源需：079 客户端二进制 WZ，或 HaRepacker PNG\\MP3 导出目录。"
