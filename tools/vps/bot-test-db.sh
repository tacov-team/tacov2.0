#!/usr/bin/env bash
# Trägt die Testserver-Datenbank in die .env des Bots ein, damit der Bot auch den Testserver spiegelt (als „Testserver“
# gekennzeichnet), und startet den Bot neu. Liest das Passwort aus /opt/tacov2-test/.db_pass (von setup-test.sh angelegt).
set -euo pipefail
BOT_ENV="${BOT_ENV:-/opt/tacov2/bot/.env}"
TEST_BASE="${TEST_BASE:-/opt/tacov2-test}"
DB_NAME="${TEST_DB_NAME:-tacov2_test}"
DB_USER="${TEST_DB_USER:-tacov2_test}"

[ -f "$BOT_ENV" ] || { echo "Bot-.env nicht gefunden: $BOT_ENV"; exit 1; }
[ -f "$TEST_BASE/.db_pass" ] || { echo "Passwortdatei fehlt: $TEST_BASE/.db_pass (setup-test.sh zuerst ausführen)"; exit 1; }
DB_PASS="$(cat "$TEST_BASE/.db_pass")"

set_kv() {
  local key="$1" val="$2"
  if grep -q "^${key}=" "$BOT_ENV"; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$BOT_ENV"
  else
    printf '%s=%s\n' "$key" "$val" >> "$BOT_ENV"
  fi
}
set_kv DB_TEST_NAME "$DB_NAME"
set_kv DB_TEST_USER "$DB_USER"
set_kv DB_TEST_PASS "$DB_PASS"
chmod 600 "$BOT_ENV"

systemctl restart tacov2-bot
sleep 2
systemctl --no-pager --lines=8 status tacov2-bot || true
echo "Fertig: Der Bot spiegelt jetzt auch $DB_NAME (als Testserver gekennzeichnet)."
