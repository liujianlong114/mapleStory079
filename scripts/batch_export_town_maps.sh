#!/usr/bin/env bash
# 批量导出 079 常用城镇地图 JSON + tile + obj + back
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"

CLIENT="${MXD079_CLIENT:-$(maple_mxd079_download)/extracted_client}"
MAX3="$(maple_max3_client_data)"
BACK_CLIENT=""
if [[ -n "${MAX3:-}" ]]; then
  BACK_CLIENT="${MAX3}/怀旧岛079MAX3_客户端"
fi

PY="$ROOT/.cache/wz-python/.venv/bin/python"
EXPORT="$ROOT/scripts/extract_wz_py/export_map_from_wz.py"

if [[ ! -x "$PY" ]]; then
  echo "❌ 未找到 wz-python，请先运行 ./scripts/ingest_full.sh"
  exit 1
fi

# wz_file:map_id:name
MAPS=(
  "000010000:1000000:彩虹村"
  "100000000:100000000:射手村"
  "101000000:101000000:魔法密林"
  "102000000:102000000:勇士部落"
  "103000000:103000000:废弃都市"
  "104000000:104000000:明珠港"
)

echo "╔══════════════════════════════════════════════╗"
echo "║  批量导出城镇地图 → client/assets/maps       ║"
echo "╚══════════════════════════════════════════════╝"
echo "客户端: $CLIENT"
echo ""

for entry in "${MAPS[@]}"; do
  IFS=':' read -r wz map_id name <<<"$entry"
  echo "==> [$map_id] $name (WZ: $wz)"
  PYTHONPATH="$ROOT/.cache/wz-python" "$PY" "$EXPORT" \
    --client "$CLIENT" \
    --map "$wz" --map-id "$map_id" --name "$name" \
    --out "$ROOT/client/assets" --force \
    ${BACK_CLIENT:+--back-client "$BACK_CLIENT"} || echo "  ⚠ 跳过 $map_id"
  echo ""
done

echo "✅ 批量导出完成。请检查 pubspec.yaml 是否包含新增 maps/tiles/* 与 maps/obj/* 子目录。"
