#!/usr/bin/env bash
# 从 MapleStory 079 客户端或 HaRepacker PNG 导出提取登录/选角/创建角色资源。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FORCE="${FORCE:-}"
FORCE_FLAG=""
if [[ "$FORCE" == "1" || "$FORCE" == "true" ]]; then
  FORCE_FLAG="--force"
fi

is_binary_wz() {
  local dir="$1"
  [[ -f "$dir/Base.wz" ]] && return 0
  [[ -d "$dir/Base" && -f "$dir/Base/Base.ini" ]] && return 0
  return 1
}

has_harepacker_png() {
  local dir="$1"
  [[ -f "$dir/UI.wz/Login.img/Title/BtLogin/normal/0.png" ]] && return 0
  [[ -f "$dir/UI.wz/Login.img/Title/BtLogin/normal/0" ]] && return 0
  return 1
}

CLIENT="${MAPLE_WZ_ROOT:-}"
if [[ -z "$CLIENT" ]]; then
  CANDIDATES=(
    "/Applications/MapleStory"
    "$HOME/MapleStory"
    "$HOME/Desktop/MapleStory"
    "/Volumes/MapleStory"
    "C:/MapleStory"
    "D:/MapleStory"
  )
  for c in "${CANDIDATES[@]}"; do
    if is_binary_wz "$c"; then
      CLIENT="$c"
      break
    fi
  done
fi

HAREPACKER="${WZ_HAREPACKER_ROOT:-}"

if [[ -n "$CLIENT" ]] && is_binary_wz "$CLIENT"; then
  echo "==> 二进制 WZ 客户端: $CLIENT"
  go run scripts/extract_wz_login/main.go --wz-root "$CLIENT" $FORCE_FLAG
  go run scripts/extract_beginner_parts/main.go --wz-root "$CLIENT" $FORCE_FLAG 2>/dev/null || \
    go run scripts/extract_beginner_parts/main.go --wz-root "$CLIENT"
elif [[ -n "$HAREPACKER" ]] && has_harepacker_png "$HAREPACKER"; then
  echo "==> HaRepacker PNG 导出: $HAREPACKER"
  go run scripts/extract_wz_harepacker/main.go --wz-root "$HAREPACKER" $FORCE_FLAG
else
  echo "未找到可用的 WZ 资源源。"
  echo ""
  echo "examples/ms079-main/wz 只有 XML 元数据（无 PNG/MP3 像素数据），无法直接解析出贴图和音乐。"
  echo ""
  echo "请选择其一："
  echo "  1) 079 客户端（含二进制 Base.wz）"
  echo "     export MAPLE_WZ_ROOT=/path/to/MapleStory"
  echo "     FORCE=1 ./scripts/setup_maple_wz.sh"
  echo ""
  echo "  2) HaRepacker「PNG\\MP3 导出」目录"
  echo "     export WZ_HAREPACKER_ROOT=/path/to/png-dump"
  echo "     FORCE=1 ./scripts/setup_maple_wz.sh"
  echo ""
  echo "HaRepacker 导出步骤：打开 UI.wz / Map.wz / Sound.wz → 右键 → PNG\\MP3 导出"
  exit 1
fi

go run scripts/build_login_scene/main.go $FORCE_FLAG
echo ""
echo "完成。运行 go run scripts/check_assets/main.go 检查资源状态。"
