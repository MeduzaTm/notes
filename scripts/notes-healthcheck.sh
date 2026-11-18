#!/usr/bin/env bash
# Проверка /healthz «Заметок»: при отказе строка в лог и код выхода 1.
set -euo pipefail

URL="${NOTES_HEALTH_URL:-http://127.0.0.1:8080/healthz}"
LOG="${NOTES_HEALTH_LOG:-/var/log/notes-health.log}"

if curl -fsS --max-time 2 -o /dev/null "$URL" 2>/dev/null; then
  exit 0
fi

echo "$(date -Is) FAIL $URL" >> "$LOG"
exit 1
