#!/usr/bin/env bash
# 尝试定位 MapleStory 079 客户端并提取登录/选角/创建角色资源。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -n "${MAPLE_WZ_ROOT:-}" && -d "$MAPLE_WZ_ROOT" ]]; then
  CLIENT="$MAPLE_WZ_ROOT"
else
  CANDIDATES=(
    "/Applications/MapleStory"
    "$HOME/MapleStory"
    "$HOME/Desktop/MapleStory"
    "/Volumes/MapleStory"
    "C:/MapleStory"
    "D:/MapleStory"
  )
  CLIENT=""
  for c in "${CANDIDATES[@]}"; do
    if [[ -f "$c/Base.wz" || -d "$c/Base" ]]; then
      CLIENT="$c"
      break
    fi
  done
fi

if [[ -z "${CLIENT:-}" ]]; then
  echo "未找到 MapleStory 079 客户端。"
  echo "请设置环境变量 MAPLE_WZ_ROOT 指向客户端目录（含 Base.wz），例如："
  echo "  export MAPLE_WZ_ROOT=/path/to/MapleStory"
  echo "  ./scripts/setup_maple_wz.sh"
  exit 1
fi

echo "使用客户端: $CLIENT"
go run scripts/extract_wz_login/main.go --wz-root "$CLIENT"
go run scripts/extract_beginner_parts/main.go --wz-root "$CLIENT"
go run scripts/build_login_scene/main.go
echo ""
echo "完成。请重启 Flutter 客户端查看原版登录界面、BGM 与创建角色 UI。"
