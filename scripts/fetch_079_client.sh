#!/usr/bin/env bash
# 自动检测 / 下载 079 客户端二进制 WZ，并提取贴图+音乐到 client/assets/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"

CLIENT_DIR="$(maple_client_dir)"
mkdir -p "$CLIENT_DIR"

is_binary_wz() {
  local dir="$1"
  [[ -f "$dir/Base.wz" ]] && file "$dir/Base.wz" 2>/dev/null | grep -qE 'data|Zip|archive' && return 0
  [[ -f "$dir/Base.wz" ]] && [[ ! -d "$dir/Base.wz" ]] && return 0
  [[ -d "$dir/Base" && -f "$dir/Base/Base.ini" ]] && return 0
  return 1
}

echo "==> 扫描本地 079 客户端…"
CANDIDATES=(
  "$CLIENT_DIR"
  "$(maple_external_root)/13-MXDtestServer-空目录-仅占位/MXDtestServer"
  "$HOME/MapleStory"
  "$HOME/Desktop/MapleStory"
  "$HOME/Downloads/MapleStory"
  "/Applications/MapleStory"
  "C:/MapleStory"
  "D:/MapleStory"
)
FOUND=""
for c in "${CANDIDATES[@]}"; do
  if [[ -n "$c" ]] && is_binary_wz "$c"; then
    FOUND="$c"
    break
  fi
done

if [[ -z "$FOUND" ]]; then
  echo ""
echo "未找到含二进制 Base.wz 的 079 客户端。"
echo ""
echo "尝试从 Dropbox 下载 UI.wz + Sound.wz + Base.wz …"
if ONLY=UI.wz,Sound.wz,Base.wz "$ROOT/scripts/download_wz_dropbox.sh"; then
  exit 0
fi
echo ""
  echo "请将完整客户端解压到："
  echo "  $CLIENT_DIR"
  echo ""
  echo "常见下载源（需自行获取）："
  echo "  • ZLHSS2 客户端: https://pan.baidu.com/s/1NEwejrLFXFKmCBxvYjWEpg  提取码 uhfg"
  echo "  • MapleStory083: https://github.com/yqr1993/MapleStory083CompleteServer/releases"
  echo ""
  echo "放置后重新运行: FORCE=1 ./scripts/fetch_079_client.sh"
  exit 1
fi

echo "✓ 找到客户端: $FOUND"
export MAPLE_WZ_ROOT="$FOUND"
FORCE=1 ./scripts/setup_maple_wz.sh
go run scripts/check_assets/main.go
