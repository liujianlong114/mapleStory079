#!/usr/bin/env bash
# 从 MapleStory 079 客户端或 HaRepacker PNG 导出提取登录/选角/创建角色资源。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"

FORCE="${FORCE:-}"
FORCE_FLAG=""
if [[ "$FORCE" == "1" || "$FORCE" == "true" ]]; then
  FORCE_FLAG="--force"
fi

is_binary_wz() {
  local dir="$1"
  [[ -f "$dir/Base.wz" ]] && [[ ! -d "$dir/Base.wz" ]] && return 0
  [[ -f "$dir/UI.wz" && -f "$dir/Sound.wz" ]] && return 0
  [[ -d "$dir/Base" && -f "$dir/Base/Base.ini" ]] && return 0
  return 1
}

is_data_img_client() {
  local dir="$1"
  [[ -f "$dir/Data/UI/Login.img" ]] && return 0
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

extract_with_wz_py() {
  local dir="$1"
  echo "==> wz-python 提取 (EMS/CMS 客户端): $dir"
  chmod +x scripts/extract_wz_py/run.sh
  EXTRACT_FULL=1 MAPLE_WZ_ROOT="$dir" MAPLE_WZ_REGION="${MAPLE_WZ_REGION:-EMS}" \
    scripts/extract_wz_py/run.sh --client "$dir" --full $FORCE_FLAG
}

if [[ -n "$CLIENT" ]] && { is_binary_wz "$CLIENT" || is_data_img_client "$CLIENT"; }; then
  if is_data_img_client "$CLIENT" || [[ "${MAPLE_WZ_REGION:-EMS}" == "EMS" ]]; then
    extract_with_wz_py "$CLIENT" || true
  fi
  if is_binary_wz "$CLIENT"; then
    echo "==> 二进制 WZ (Go/wzexplorer): $CLIENT"
    if ! go run scripts/extract_wz_login/main.go --wz-root "$CLIENT" $FORCE_FLAG; then
      echo "⚠️  wzexplorer 提取失败（私服常见），已尝试 wz-python。"
    fi
    go run scripts/extract_beginner_parts/main.go --wz-root "$CLIENT" $FORCE_FLAG 2>/dev/null || \
      go run scripts/extract_beginner_parts/main.go --wz-root "$CLIENT" || true
  fi
elif [[ -n "$HAREPACKER" ]] && has_harepacker_png "$HAREPACKER"; then
  echo "==> HaRepacker PNG 导出: $HAREPACKER"
  go run scripts/extract_wz_harepacker/main.go --wz-root "$HAREPACKER" $FORCE_FLAG
else
  echo "未找到可用的 WZ 资源源。"
  echo ""
  echo "$(maple_ms079_main)/wz 只有 XML 元数据（无 PNG/MP3 像素数据），无法直接解析出贴图和音乐。"
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

go run scripts/export_login_manifest/main.go
echo ""
echo "完成。运行 go run scripts/check_assets/main.go 检查资源状态。"
