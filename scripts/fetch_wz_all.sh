#!/usr/bin/env bash
# 尝试下载 079 WZ；失败时列出已验证可用的客户端镜像。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/external_paths.sh
source "$ROOT/scripts/lib/external_paths.sh"
OUT="$(maple_client_dir)"
mkdir -p "$OUT"

echo "==> 079 客户端资源获取"
echo ""

# Dropbox（本机常不可用）
echo "→ 尝试 Dropbox …"
if ONLY=List.wz "$ROOT/scripts/download_wz_dropbox.sh" 2>/dev/null; then
  echo "  Dropbox 可用，继续下载 UI.wz + Sound.wz …"
  ONLY=UI.wz,Sound.wz,Base.wz,Map.wz "$ROOT/scripts/download_wz_dropbox.sh" && exit 0
fi
echo "  Dropbox 不可用"
echo ""

# 已有 WZ
if [[ -f "$OUT/UI.wz" && -f "$OUT/Sound.wz" ]] && [[ ! -d "$OUT/UI.wz" ]]; then
  echo "✓ 已存在 WZ: $OUT"
  MAPLE_CLIENT_DIR="$OUT" "$ROOT/scripts/ingest_client.sh"
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ZLHSS2 旧链 (uhfg) 已失效，请改用下列镜像之一："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "【推荐 1】079MAX3 单机整合包（客户端+服务端+数据库）"
echo "  https://pan.baidu.com/s/1B04dYanPGWhcwO_qylpH0Q"
echo "  提取码: MAX3"
echo "  来源: https://www.jiaosf.com/yxym-3925-1-1.html"
echo ""
echo "【推荐 2】ms079-main 官方文档客户端 → 阿里云盘"
echo "  https://www.aliyundrive.com/s/RzCSPTXc5RA"
echo "  短链: https://alywp.net/2bBtbJ"
echo ""
echo "【推荐 3】MapleStory-Server-079 配套客户端"
echo "  https://pan.baidu.com/s/1gDt0qN-AoU9fGvhp1TLuJA"
echo "  提取码: rcan"
echo ""
echo "【备选 4】ZXMS079 仿官客户端"
echo "  https://pan.baidu.com/s/1AliMMgX1adylzB8JMbeUbQ"
echo "  提取码: 3gpz"
echo ""
echo "【备选 5】079 数据包（WZ 资源）"
echo "  https://pan.baidu.com/s/1w4DpXIX_-19msuhrQx65gQ"
echo "  提取码: 1328"
echo ""
echo "【备选 6】079MAX4 整合版"
echo "  https://pan.baidu.com/s/1pF8mPFh0y9NQuMG_J6Kjaw"
echo "  （og1.in/8fpeXM 跳转，提取码见论坛）"
echo ""
echo "【备选 7】七玩网整合服务端+客户端（需登录）"
echo "  https://www.7chaowan.com/b/0dd715  提取码: yyun"
echo ""
echo "探测镜像是否仍有效: ./scripts/list_client_mirrors.sh"
echo ""
echo "解压后执行:"
echo "  MAPLE_CLIENT_DIR=/你的/解压路径 ./scripts/ingest_client.sh"
echo "  cd client && flutter run -d chrome --web-port=5173"
echo ""
exit 1
