#!/usr/bin/env bash
# 探测已知 079 客户端镜像是否仍有效（百度「链接不存在」= 失效）
set -uo pipefail

probe_baidu() {
  local url="$1" name="$2" code="${3:-}"
  local html
  html=$(curl -sL --connect-timeout 12 --max-time 18 "$url" 2>/dev/null || true)
  if echo "$html" | rg -q '链接不存在|分享的文件已经被取消'; then
    echo "  ✗ $name — 已失效"
    echo "      $url"
  elif echo "$html" | rg -q '请输入提取码'; then
    echo "  ✓ $name — 有效（需提取码: ${code:-见论坛说明}）"
    echo "      $url"
  elif echo "$html" | rg -q 'file_list|fs_id|shareid'; then
    echo "  ✓ $name — 有效（可能无需提取码）"
    echo "      $url"
  else
    echo "  ? $name — 无法判定，请浏览器打开"
    echo "      $url"
  fi
}

echo "=== 079 客户端镜像探测 $(date '+%Y-%m-%d') ==="
echo ""

probe_baidu "https://pan.baidu.com/s/1NEwejrLFXFKmCBxvYjWEpg" "ZLHSS2 客户端（旧）" "uhfg"
probe_baidu "https://pan.baidu.com/s/1B04dYanPGWhcwO_qylpH0Q" "079MAX3 单机整合包（推荐）" "MAX3"
probe_baidu "https://pan.baidu.com/s/1gDt0qN-AoU9fGvhp1TLuJA" "MapleStory-Server-079 客户端" "rcan"
probe_baidu "https://pan.baidu.com/s/1AliMMgX1adylzB8JMbeUbQ" "ZXMS079 仿官客户端" "3gpz"
probe_baidu "https://pan.baidu.com/s/1w4DpXIX_-19msuhrQx65gQ" "079 数据包" "1328"
probe_baidu "https://pan.baidu.com/s/1pF8mPFh0y9NQuMG_J6Kjaw" "079MAX4 整合版" ""
probe_baidu "https://pan.baidu.com/s/1gAOhxhwxd1T4bqX8HSoFNQ" "079 过 HS 补丁包" "7i0u"

echo ""
echo "=== 其他网盘 ==="
echo "  ✓ ms079-main 客户端 → 阿里云盘"
echo "      https://www.aliyundrive.com/s/RzCSPTXc5RA"
echo "      （短链 https://alywp.net/2bBtbJ ）"
echo ""
echo "  ? 七玩网 ZXMS079 整合包（需登录论坛）"
echo "      https://www.7chaowan.com/b/0dd715  提取码: yyun"
echo ""
echo "  ? 079MAX3 论坛帖"
echo "      https://www.jiaosf.com/yxym-3925-1-1.html"
echo ""
echo "下载后: MAPLE_CLIENT_DIR=/解压路径 ./scripts/ingest_client.sh"
