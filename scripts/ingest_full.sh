#!/usr/bin/env bash
# 从两个已下载客户端包完整提取资源 → client/assets，并自检。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"

DOWNLOAD_MXD="$(maple_mxd079_download)"
DOWNLOAD_MAX3="$(maple_max3_download)"
MXD079="${MXD079_CLIENT:-$DOWNLOAD_MXD/extracted_client}"
MAX3="$(maple_max3_client_data)"
MAX3="${MAX3:+$MAX3/怀旧岛079MAX3_客户端}"
MAX3_XML="$(maple_max3_map_xml)"
DEST="$(maple_client_dir)"

ensure_extracted() {
  local exe="$DOWNLOAD_MXD/079客户端.exe"
  local dest="$DOWNLOAD_MXD/extracted_client"
  if [[ ! -f "$dest/UI.wz" && -f "$exe" ]]; then
    echo "==> 解压 冒险岛079 客户端 (NSIS) …"
    mkdir -p "$dest"
    if command -v 7z >/dev/null 2>&1; then
      7z x -y "-o$dest" "$exe" >/dev/null
    else
      unar -o "$(dirname "$dest")" -f "$exe" 2>/dev/null || true
    fi
  fi
  if [[ -f "$dest/UI.wz" ]]; then
    MXD079="$dest"
  fi
  local max3_extract="$DEST/extracted/max3"
  if [[ -d "$DOWNLOAD_MAX3" && ! -f "${MAX3:-}/Data/UI/Login.img" ]]; then
    rar="$(find "$DOWNLOAD_MAX3" -maxdepth 2 -name "*客户端*.rar" 2>/dev/null | head -1)"
    if [[ -n "$rar" ]]; then
      echo "==> 解压 MAX3 客户端 RAR …"
      mkdir -p "$max3_extract"
      unar -o "$max3_extract" -f "$rar" 2>/dev/null || true
      MAX3="$(maple_max3_client_data)"
      MAX3="${MAX3:+$MAX3/怀旧岛079MAX3_客户端}"
    fi
  fi
}

ensure_extracted

[[ -f "$MXD079/UI.wz" ]] || MXD079="$(find "$DOWNLOAD_MXD" "$DEST" -name UI.wz 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)"
[[ -f "${MAX3:-}/Data/UI/Login.img" ]] || MAX3="$(find "$DEST/extracted/max3" -path '*/Data/UI/Login.img' 2>/dev/null | head -1 | xargs dirname 2>/dev/null | xargs dirname 2>/dev/null || true)"

if [[ ! -f "$MXD079/UI.wz" ]]; then
  echo "❌ 未找到 冒险岛079 二进制客户端 (UI.wz): $MXD079"
  echo "   外部资源目录: $(maple_external_root)"
  exit 1
fi

echo "╔══════════════════════════════════════════════════╗"
echo "║  完整资源提取：冒险岛079 + MAX3 怀旧岛            ║"
echo "╚══════════════════════════════════════════════════╝"
echo "主客户端: $MXD079"
echo "补充客户端: ${MAX3:-无}"
echo "ingest 目录: $DEST"
echo ""

mkdir -p "$DEST"
for f in Base.wz UI.wz Sound.wz Map.wz Character.wz List.wz Mob.wz Npc.wz; do
  [[ -f "$MXD079/$f" ]] && cp -f "$MXD079/$f" "$DEST/" && echo "  copied $f"
done

chmod +x scripts/extract_wz_py/run.sh
echo ""
echo "==> [1/5] 冒险岛079 — 登录 UI + 部件 + BGM"
EXTRACT_FULL=1 FORCE=1 MAPLE_WZ_REGION=EMS \
  scripts/extract_wz_py/run.sh --client "$MXD079" --full --force

if [[ -n "${MAX3:-}" && -f "$MAX3/Data/UI/Login.img" ]]; then
  echo ""
  echo "==> [2/5] MAX3 — 补 logo / signboard / 缺项"
  FORCE=1 MAPLE_WZ_REGION=EMS \
    scripts/extract_wz_py/run.sh --client "$MAX3" --force || true
  EXTRACT_FULL=1 FORCE=1 MAPLE_WZ_REGION=EMS \
    scripts/extract_wz_py/run.sh --client "$MAX3" --full --force || true
else
  echo "⚠  跳过 MAX3（未找到 Data/UI/Login.img）"
fi

echo ""
echo "==> [3/7] 彩虹村地图元数据 + 视差 Back（官方 Map.wz + MAX3 grassySoil）"
BACK_CLIENT=""
[[ -f "${MAX3:-}/Data/UI/Login.img" ]] && BACK_CLIENT="$MAX3"
PYTHONPATH="$ROOT/.cache/wz-python" \
  "$ROOT/.cache/wz-python/.venv/bin/python" "$ROOT/scripts/extract_wz_py/export_map_from_wz.py" \
  --client "$MXD079" --map 000010000 --map-id 1000000 --out "$ROOT/client/assets" --force \
  ${BACK_CLIENT:+--back-client "$BACK_CLIENT"} 2>/dev/null || \
  go run scripts/export_rainbow_map/main.go
go run scripts/export_maplogin_layers/main.go 2>/dev/null || true
go run scripts/export_map_life/main.go 2>/dev/null || true

echo ""
echo "==> [4/7] Mob/Npc 游戏精灵（Mob.wz / Npc.wz）"
chmod +x scripts/extract_wz_py/run.sh
FORCE=1 MAPLE_WZ_REGION=EMS \
  scripts/extract_wz_py/run.sh --client "$MXD079" --mobs-npcs --all --force 2>/dev/null || \
FORCE=1 MAPLE_WZ_REGION=EMS \
  PYTHONPATH="$ROOT/.cache/wz-python" \
  "$ROOT/.cache/wz-python/.venv/bin/python" "$ROOT/scripts/extract_wz_py/extract_mobs_npcs.py" \
  --client "$MXD079" --out "$ROOT/client/assets" --all --force

echo ""
echo "==> [4b/7] 地图视差 Back（Map.wz/Back/*.img）"
PYTHONPATH="$ROOT/.cache/wz-python" \
  "$ROOT/.cache/wz-python/.venv/bin/python" "$ROOT/scripts/extract_wz_py/extract_map_backs.py" \
  --client "$MXD079" --out "$ROOT/client/assets" --sets grassySoil grassySoil_new --force 2>/dev/null || true

echo ""
echo "==> [5/7] 079 标准登录 manifest（MapLogin2 视差，不用街机框 PNG）"
go run scripts/export_login_manifest/main.go

UI="$ROOT/client/assets/images/ui/login"
for n in 1 2; do
  for state in normal over pressed; do
    src="$UI/btn_world_0_${state}.png"
    dst="$UI/btn_world_${n}_${state}.png"
    [[ -f "$src" && ! -f "$dst" ]] && cp -f "$src" "$dst"
  done
done

echo ""
echo "==> [7/7] 资源自检"
go run scripts/check_assets/main.go

echo ""
if command -v flutter >/dev/null 2>&1; then
  echo "==> Flutter analyze"
  (cd client && flutter analyze --no-fatal-infos 2>&1 | tail -20) || true
  echo ""
  echo "✅ 提取完成。启动测试:"
  echo "   cd client && flutter run -d chrome --web-port=5173"
else
  echo "✅ 提取完成（未安装 flutter，跳过 analyze）"
  echo "   cd client && flutter run -d chrome --web-port=5173"
fi
