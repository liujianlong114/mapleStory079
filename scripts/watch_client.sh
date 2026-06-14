#!/usr/bin/env bash
# 监视外部 maple-client 或 MAPLE_CLIENT_DIR，一旦出现 UI.wz + Sound.wz 自动提取资源。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"
WATCH="$(maple_client_dir)"

echo "监视目录: $WATCH"
echo "将 079 客户端 WZ 放入此目录后自动运行 ingest …"
echo "（Ctrl+C 退出）"
echo ""

while true; do
  if [[ -f "$WATCH/UI.wz" && -f "$WATCH/Sound.wz" ]] && [[ ! -d "$WATCH/UI.wz" ]]; then
    sz=$(stat -f%z "$WATCH/UI.wz" 2>/dev/null || stat -c%s "$WATCH/UI.wz")
    if [[ "$sz" -gt 1000000 ]]; then
      echo "✓ 检测到二进制 WZ，开始提取 …"
      MAPLE_CLIENT_DIR="$WATCH" "$ROOT/scripts/ingest_client.sh" && exit 0
    fi
  fi
  sleep 3
done
