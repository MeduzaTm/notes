#!/usr/bin/env bash
# Бэкап данных «Заметок»: tar.gz, хранение 7 последних копий.
set -euo pipefail

DATA_DIR="${NOTES_DATA_DIR:-/var/lib/notes}"
BACKUP_DIR="${NOTES_BACKUP_DIR:-/var/backups/notes}"
LOCK_FILE="${NOTES_LOCK_FILE:-/run/lock/notes-backup.lock}"
KEEP=7

# не запускаться дважды одновременно
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  logger -t notes-backup "уже запущен, выхожу" 9>&-
  exit 0
fi

mkdir -p "$BACKUP_DIR"

# пишем во временный файл, чтобы не оставить битый архив с настоящим именем
tmp=$(mktemp "$BACKUP_DIR/.notes-XXXXXX.tmp")
trap 'rm -f "$tmp"' EXIT

stamp=$(date +%Y%m%d-%H%M)
# код 1 у tar значит «файл менялся во время чтения»: архив есть, это не авария
# 9>&-: потомок не наследует замок (см. раздел про flock)
tar -czf "$tmp" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")" 9>&- || [ $? -eq 1 ]
mv "$tmp" "$BACKUP_DIR/notes-$stamp.tar.gz"

# ротация: оставляем KEEP самых новых
# bash раскрывает шаблон в алфавитном порядке, а в имени дата, значит, старые идут первыми
backups=("$BACKUP_DIR"/notes-*.tar.gz)
extra=$(( ${#backups[@]} - KEEP ))
if (( extra > 0 )); then
  rm -f -- "${backups[@]:0:extra}"
fi

# метка успеха: алерт строят на её возрасте (старше 26 часов), а не на факте запуска
touch "$BACKUP_DIR/.last_ok"
logger -t notes-backup "готово: notes-$stamp.tar.gz" 9>&-
