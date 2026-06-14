#!/usr/bin/env bash
# 扫描常见路径中的 079 客户端，复制 WZ 到外部 maple-client 并提取资源。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"
DEST="$(maple_client_dir)"
mkdir -p "$DEST"

is_client_dir() {
  local d="$1"
  [[ -f "$d/UI.wz" && -f "$d/Sound.wz" ]] && return 0
  [[ -f "$d/Base.wz" && ! -d "$d/Base.wz" ]] && return 0
  [[ -f "$d/Data/UI/Login.img" ]] && return 0
  return 1
}

echo "扫描 079 客户端 …"
FOUND=""
CANDIDATES=(
  "$DEST"
  "$DEST/extracted/mxd079/079客户端"
  "$HOME/Downloads/冒险岛079/extracted_client"
  "$HOME/Downloads/冒险岛079/079客户端"
  "$HOME/Downloads/【怀旧岛079MAX3】2022虎年贺岁版/怀旧岛079MAX3_客户端"
  "$DEST/extracted/max3/【怀旧岛079MAX3】2022虎年贺岁版/怀旧岛079MAX3_客户端"
  "$HOME/Downloads/MapleStory"
  "$HOME/Downloads/冒险岛"
  "$HOME/Downloads/mxd"
  "$HOME/Downloads/MapleStory079"
  "$HOME/Downloads/079"
  "$HOME/Desktop/MapleStory"
  "$HOME/MapleStory"
  "/Applications/MapleStory"
  "$(maple_external_root)/13-MXDtestServer-空目录-仅占位/MXDtestServer"
  "$(maple_client_dir)"
)
while IFS= read -r d; do
  CANDIDATES+=("$d")
done < <(find "$HOME/Downloads" "$HOME/Desktop" -maxdepth 3 -type f -name "UI.wz" 2>/dev/null | xargs -I{} dirname {})

for d in "${CANDIDATES[@]}"; do
  [[ -z "$d" || ! -d "$d" ]] && continue
  if is_client_dir "$d"; then
    FOUND="$d"
    break
  fi
done

if [[ -z "$FOUND" ]]; then
  echo "❌ 未找到含 UI.wz + Sound.wz 的客户端目录。"
  echo ""
  echo "ZLHSS2 旧百度链 (uhfg) 已失效，请改用下列镜像："
  echo ""
  echo "  [推荐] 079MAX3 单机整合包"
  echo "    https://pan.baidu.com/s/1B04dYanPGWhcwO_qylpH0Q  提取码 MAX3"
  echo ""
  echo "  [推荐] ms079-main 客户端（阿里云盘）"
  echo "    https://www.aliyundrive.com/s/RzCSPTXc5RA"
  echo ""
  echo "  [备选] MapleStory-Server-079 客户端"
  echo "    https://pan.baidu.com/s/1gDt0qN-AoU9fGvhp1TLuJA  提取码 rcan"
  echo ""
  echo "  更多镜像: ./scripts/list_client_mirrors.sh"
  echo ""
  echo "下载后放入外部目录 $(maple_client_dir) 并运行："
  echo "  ./scripts/watch_client.sh    # 自动检测并提取"
  echo ""
  echo "或手动指定："
  echo "  MAPLE_CLIENT_DIR=/你的/客户端路径 ./scripts/ingest_client.sh"
  exit 1
fi

echo "✓ 发现客户端: $FOUND"
if [[ "$FOUND" != "$DEST" ]]; then
  echo "→ 复制 WZ 到 $DEST …"
  for f in Base.wz UI.wz Sound.wz Map.wz Character.wz List.wz; do
    [[ -f "$FOUND/$f" ]] && cp -f "$FOUND/$f" "$DEST/" && echo "  $f"
  done
fi

export MAPLE_CLIENT_DIR="$DEST"
FORCE=1 "$ROOT/scripts/replica.sh"
