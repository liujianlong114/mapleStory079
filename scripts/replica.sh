#!/usr/bin/env bash
# 079 完全复刻 — 一键：下载 WZ（若可访问）→ 提取贴图/音乐 → 合成场景 → 检查资源
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"
CLIENT="$(maple_client_dir)"

echo "╔══════════════════════════════════════════════════╗"
echo "║  MapleStory 079 资源复刻管线                      ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# 1) 尝试 Dropbox 下载（需本机可访问 dropbox.com）
if [[ ! -f "$CLIENT/Base.wz" ]] || [[ -d "$CLIENT/Base.wz" ]]; then
  echo "→ 尝试下载 UI.wz + Sound.wz + Base.wz …"
  ONLY=UI.wz,Sound.wz,Base.wz,List.wz "$ROOT/scripts/download_wz_dropbox.sh" || true
fi

# 2) 检测客户端
has_wz=false
if [[ -f "$CLIENT/Base.wz" ]] && [[ ! -d "$CLIENT/Base.wz" ]]; then has_wz=true; fi
if [[ -f "$CLIENT/UI.wz" ]] && [[ -f "$CLIENT/Sound.wz" ]]; then has_wz=true; fi

if $has_wz; then
  echo "→ 从二进制 WZ 提取原版 UI / BGM …"
  export MAPLE_WZ_ROOT="$CLIENT"
  FORCE=1 "$ROOT/scripts/setup_maple_wz.sh"
else
  echo "⚠  未找到二进制 WZ，使用 WZ-XML 布局 + 程序化资源（非 100% 原画）"
  echo ""
  echo "  请任选其一获取客户端后重新运行本脚本："
  echo "  • ./scripts/fetch_wz_all.sh          # 列出全部可用镜像"
  echo "  • ./scripts/list_client_mirrors.sh   # 探测链接是否失效"
  echo "  • 079MAX3: https://pan.baidu.com/s/1B04dYanPGWhcwO_qylpH0Q  提取码 MAX3"
  echo "  • 阿里云盘: https://www.aliyundrive.com/s/RzCSPTXc5RA"
  echo ""
  go run scripts/export_maplogin_layers/main.go
  go run scripts/export_rainbow_map/main.go
  go run scripts/generate_bgm/main.go
  go run scripts/export_login_manifest/main.go
  go run scripts/import_wz/main.go 2>/dev/null || true
fi

echo ""
go run scripts/check_assets/main.go 2>/dev/null || true
echo ""
echo "完成。启动: cd client && flutter run -d chrome --web-port=5173"
