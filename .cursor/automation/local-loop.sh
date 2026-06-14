#!/usr/bin/env bash
# 本地 30 分钟循环：唤醒 Cursor Agent 继续推进（需 IDE 保持打开）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROMPT_FILE="$ROOT/.cursor/automation/overnight-prompt.md"
LOG="$ROOT/.cursor/automation/loop.log"
INTERVAL="${LOOP_INTERVAL_SEC:-1800}"

mkdir -p "$(dirname "$LOG")"
echo "[$(date -Iseconds)] local loop started interval=${INTERVAL}s" >>"$LOG"

while true; do
  echo "[$(date -Iseconds)] === loop tick ===" >>"$LOG"
  # 健康检查
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && echo "  backend ok" >>"$LOG" || echo "  backend DOWN" >>"$LOG"
  curl -sf -o /dev/null http://localhost:5173/ 2>/dev/null && echo "  frontend ok" >>"$LOG" || echo "  frontend DOWN" >>"$LOG"
  # 记录待办缺口
  if [[ -f "$ROOT/PROJECT_PLAN.md" ]]; then
    grep -E '^\| [0-9]+ \|' "$ROOT/PROJECT_PLAN.md" | head -15 >>"$LOG" 2>/dev/null || true
  fi
  echo "[$(date -Iseconds)] next tick in ${INTERVAL}s — read $PROMPT_FILE" >>"$LOG"
  sleep "$INTERVAL"
done
