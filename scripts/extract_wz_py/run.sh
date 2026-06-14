#!/usr/bin/env bash
# 确保 wz-python 可用并运行 extract.py
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CACHE="${WZ_PY_HOME:-$ROOT/.cache/wz-python}"
VENV="${WZ_PY_VENV:-$CACHE/.venv}"

if [[ ! -d "$CACHE/wzpy" ]]; then
  echo "==> 克隆 wz-python 到 $CACHE"
  mkdir -p "$(dirname "$CACHE")"
  git clone --depth 1 https://github.com/Leonana69/wz-python "$CACHE"
fi

if [[ ! -x "$VENV/bin/python" ]]; then
  echo "==> 创建 Python 虚拟环境"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q -r "$ROOT/scripts/extract_wz_py/requirements.txt"
fi

export PYTHONPATH="$CACHE${PYTHONPATH:+:$PYTHONPATH}"
exec "$VENV/bin/python" "$ROOT/scripts/extract_wz_py/extract.py" "$@"
