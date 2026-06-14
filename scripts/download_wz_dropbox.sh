#!/usr/bin/env bash
# 从 Advanced-MapleLauncher 记录的 Dropbox 直链下载 079 二进制 WZ。
# 在本机网络可访问 Dropbox 时运行；下载完成后自动提取资源。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"
OUT="$(maple_client_dir)"
mkdir -p "$OUT"
cd "$OUT"

declare -A WZ=(
  [Base.wz]="https://www.dropbox.com/s/zi7oaam63gqearh/Base.wz?dl=1"
  [UI.wz]="https://www.dropbox.com/s/bdxywid1cdw2xxm/UI.wz?dl=1"
  [Sound.wz]="https://www.dropbox.com/s/lpmg415a8owtzvh/Sound.wz?dl=1"
  [Map.wz]="https://www.dropbox.com/s/n02zawj3ynq8nce/Map.wz?dl=1"
  [Character.wz]="https://www.dropbox.com/s/2h8e59h566kanwa/Character.wz?dl=1"
  [Mob.wz]="https://www.dropbox.com/s/9cwdodqpfsjwa4k/Mob.wz?dl=1"
  [Npc.wz]="https://www.dropbox.com/s/48vxli6nxpl46hq/Npc.wz?dl=1"
  [Item.wz]="https://www.dropbox.com/s/dvoub5hu52238v9/Item.wz?dl=1"
  [Effect.wz]="https://www.dropbox.com/s/irxtpocq87h1ss2/Effect.wz?dl=1"
  [String.wz]="https://www.dropbox.com/s/mnjpuwomnul05da/String.wz?dl=1"
  [Skill.wz]="https://www.dropbox.com/s/rsoq7wz4ilj404w/Skill.wz?dl=1"
  [List.wz]="https://www.dropbox.com/s/7bfjubjiksc9vpp/List.wz?dl=1"
)

ONLY="${ONLY:-UI.wz,Sound.wz,Base.wz}"
IFS=',' read -ra WANT <<< "$ONLY"

GHFAST="${GHFAST_MIRROR:-https://ghfast.top}"

download_github_release() {
  local url="$1" out="$2"
  if [[ -f "$out" ]] && [[ $(stat -f%z "$out" 2>/dev/null || stat -c%s "$out") -gt 100000 ]]; then
    echo "  ✓ 已有 $out"
    return 0
  fi
  echo "  ↓ $out (GitHub via ghfast) …"
  curl -L --fail --connect-timeout 30 --retry 2 -o "$out.part" "${GHFAST}/${url}" && mv "$out.part" "$out" && return 0
  return 1
}

download_one() {
  local name="$1" url="$2"
  if [[ -f "$name" ]] && [[ $(stat -f%z "$name" 2>/dev/null || stat -c%s "$name") -gt 1000 ]]; then
    echo "  ✓ 已有 $name"
    return 0
  fi
  echo "  ↓ $name …"
  if curl -L --fail --connect-timeout 30 --retry 3 --retry-delay 5 -C - -o "$name.part" "$url"; then
    mv "$name.part" "$name"
    echo "  ✓ $name ($(ls -lh "$name" | awk '{print $5}'))"
    return 0
  fi
  echo "  ✗ $name 下载失败"
  return 1
}

echo "==> 下载目录: $OUT"

# GitHub Releases（本环境可经 ghfast 加速；不含完整 WZ，仅备用服务端包）
download_github_release \
  "https://github.com/yqr1993/MapleStory083CompleteServer/releases/download/V1.0.0/MXDtestServer.zip" \
  "$OUT/MXDtestServer.zip" || true

ok=0 fail=0
for name in "${WANT[@]}"; do
  name="${name// /}"
  url="${WZ[$name]:-}"
  if [[ -z "$url" ]]; then
    echo "  ? 未知: $name"
    continue
  fi
  if download_one "$name" "$url"; then ((ok++)); else ((fail++)); fi
done

if [[ $ok -gt 0 ]] && [[ -f Base.wz ]] && [[ ! -d Base.wz ]]; then
  echo ""
  echo "==> 提取登录 UI + BGM…"
  cd "$ROOT"
  export MAPLE_WZ_ROOT="$OUT"
  FORCE=1 ./scripts/setup_maple_wz.sh || true
elif [[ $ok -eq 0 ]]; then
  echo ""
  echo "❌ 未下载到任何 WZ 文件（Dropbox 可能不可达）"
  echo "   请运行: ./scripts/fetch_wz_all.sh  查看百度网盘链接"
  exit 1
else
  echo ""
  echo "⚠ 已下载部分 WZ，但 Base.wz 无效。可继续手动放置 UI.wz + Sound.wz 后运行 ingest_client.sh"
fi

echo ""
echo "完成。运行: go run scripts/check_assets/main.go"
