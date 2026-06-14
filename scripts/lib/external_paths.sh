#!/usr/bin/env bash
# 外部参考资源路径（与 mapleStory079 仓库同级目录 mapleStory079-external）
# 用法: source "$(dirname "$0")/lib/external_paths.sh"  或  source scripts/lib/external_paths.sh

_maple_script_lib_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

maple_project_root() {
  if [[ -n "${MAPLE_PROJECT_ROOT:-}" ]]; then
    echo "$MAPLE_PROJECT_ROOT"
    return
  fi
  local lib
  lib="$(_maple_script_lib_dir)"
  cd "$lib/../.." && pwd
}

maple_external_root() {
  if [[ -n "${MAPLE_EXTERNAL_ROOT:-}" ]]; then
    echo "$MAPLE_EXTERNAL_ROOT"
    return
  fi
  local root
  root="$(maple_project_root)"
  echo "$(dirname "$root")/mapleStory079-external"
}

# ★ 本项目 actively 使用的子路径
maple_ms079_main() {
  echo "$(maple_external_root)/02-★ms079-main-业务规则对照-登录创角禁名-WZ-XML"
}

maple_client_dir() {
  echo "${MAPLE_CLIENT_DIR:-$(maple_external_root)/03-★maple-client-ingest工作目录-WZ副本-脚本自动复制}"
}

maple_mxd079_download() {
  echo "${MXD079_DOWNLOAD:-$(maple_external_root)/00-官方客户端-冒险岛079-资源提取主源-WZ安装包与extracted_client}"
}

maple_max3_download() {
  echo "${MAX3_DOWNLOAD:-$(maple_external_root)/01-MAX3怀旧岛-补全grassySoil与Obj缺项-Data客户端}"
}

maple_max3_client_data() {
  local base extracted
  base="$(maple_client_dir)/extracted/max3"
  if [[ -d "$base" ]]; then
    extracted="$(find "$base" -path '*/怀旧岛079MAX3_客户端/Data' -type d 2>/dev/null | head -1)"
    if [[ -n "$extracted" ]]; then
      dirname "$extracted"
      return
    fi
  fi
  find "$(maple_max3_download)" -path '*/怀旧岛079MAX3_客户端' -type d 2>/dev/null | head -1
}

maple_max3_map_xml() {
  local base
  base="$(maple_client_dir)/extracted/max3"
  find "$base" "$(maple_max3_download)" -path '*/怀旧岛079MAX3_服务端/wz/Map.wz/Map/Map0/000010000.img.xml' 2>/dev/null | head -1
}
