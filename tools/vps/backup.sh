#!/usr/bin/env bash
# TacoV · Datenbank-Backup (Punkt 1.7): mysqldump nach /opt/tacov2/backups, 14 Tage aufbewahren.
# Läuft täglich 05:30 Uhr per Cron (deploy.sh richtet den Eintrag ein) und vor jedem Deploy.
# Zugangsdaten kommen aus server.cfg (set tacov_db "mysql://user:pass@host:port/db"); nichts wird ausgegeben.
set -euo pipefail
BASE="${BASE:-/opt/tacov2}"
KEEP_DAYS="${KEEP_DAYS:-14}"
OUT="$BASE/backups"
CFG="$BASE/server/server.cfg"

url=$(grep -E '^set tacov_db ' "$CFG" | head -1 | sed -E 's/^set tacov_db +"?([^"]+)"?.*/\1/')
[ -n "$url" ] || { echo "backup: tacov_db fehlt in server.cfg"; exit 1; }
# mysql://user:pass@host:port/db
rest="${url#mysql://}"
creds="${rest%%@*}"; hostpart="${rest#*@}"
user="${creds%%:*}"; pass="${creds#*:}"
host="${hostpart%%/*}"; db="${hostpart#*/}"
port="${host##*:}"; host="${host%%:*}"
[ "$port" = "$host" ] && port=3306

mkdir -p "$OUT"
stamp=$(date +%Y%m%d-%H%M)
file="$OUT/${db}-${stamp}.sql.gz"
MYSQL_PWD="$pass" mysqldump --single-transaction --quick --routines --triggers -h "$host" -P "$port" -u "$user" "$db" | gzip > "$file"
chmod 600 "$file"
find "$OUT" -name "${db}-*.sql.gz" -mtime "+$KEEP_DAYS" -delete
echo "backup: $(basename "$file") ($(du -h "$file" | cut -f1)), $(ls "$OUT" | wc -l) Dateien"
