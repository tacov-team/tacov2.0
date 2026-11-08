#!/usr/bin/env bash
# Lässt den Discord-Bot aus dem Live-Checkout (main, /opt/tacov2) oder dem Test-Checkout (develop, /opt/tacov2-test) laufen.
# Die .env bleibt immer /opt/tacov2/bot/.env (Token und Datenbanken). Nutzung: bot-use-branch.sh develop | main
set -euo pipefail
WHICH="${1:-}"
LIVE=/opt/tacov2
TEST=/opt/tacov2-test
SVC_USER="${SVC_USER:-tacov2}"
DROPIN=/etc/systemd/system/tacov2-bot.service.d
case "$WHICH" in
  develop)
    [ -d "$TEST/bot" ] || { echo "Test-Checkout fehlt: $TEST (setup-test.sh)"; exit 1; }
    ln -sfn "$LIVE/bot/.env" "$TEST/bot/.env"
    sudo -u "$SVC_USER" bash -c "cd $TEST/bot && npm install --omit=dev --no-audit --no-fund 2>&1 | tail -1"
    mkdir -p "$DROPIN"
    printf '[Service]\nWorkingDirectory=%s/bot\n' "$TEST" > "$DROPIN/branch.conf"
    echo "Bot läuft ab jetzt aus $TEST/bot (develop)."
    ;;
  main)
    rm -f "$DROPIN/branch.conf"
    echo "Bot läuft ab jetzt aus $LIVE/bot (main)."
    ;;
  *) echo "Nutzung: $0 develop | main"; exit 1 ;;
esac
systemctl daemon-reload
systemctl restart tacov2-bot
sleep 2
systemctl --no-pager --lines=6 status tacov2-bot || true
