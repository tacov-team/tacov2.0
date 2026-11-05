#!/usr/bin/env bash
# TacoV · Neuen Stand von main einspielen und Dienste neu starten. Als root oder tacov ausführen.
set -euo pipefail
BASE="/opt/tacov2"
SVC_USER="tacov2"

cd "$BASE"
sudo -u "$SVC_USER" git pull --ff-only
echo "== Bot-Abhängigkeiten"
sudo -u "$SVC_USER" bash -c "cd $BASE/bot && npm install --omit=dev --no-audit --no-fund 2>&1 | tail -2"
echo "== Datenbank-Treiber"
sudo -u "$SVC_USER" bash -c "cd '$BASE/server/resources/[tacov]/tacov_db' && npm install --omit=dev --no-audit --no-fund 2>&1 | tail -2"
[ -d "$BASE/server/resources/[tacov]/tacov_db/node_modules/mysql2" ] || { echo "FEHLER: mysql2 wurde nicht installiert."; exit 1; }
# Alte Fremd-Resource entfernen, falls noch vorhanden
rm -rf "$BASE/server/resources/[external]"
sed -i '/^ensure oxmysql/d' "$BASE/server/server.cfg"

if [ -d "$BASE/ui" ] && [ -f "$BASE/ui/package.json" ]; then
  echo "== UI bauen"
  sudo -u "$SVC_USER" bash -c "cd $BASE/ui && npm install --no-audit --no-fund 2>&1 | tail -1 && npm run build 2>&1 | tail -3"
fi

systemctl restart tacov2-bot
systemctl restart tacov2-server
echo "Deploy abgeschlossen: $(git -C "$BASE" log --oneline -1)"
