#!/usr/bin/env bash
# TacoV · Neuen Stand von main einspielen und Dienste neu starten. Als root oder tacov ausführen.
set -euo pipefail
BASE="/opt/tacov2"
SVC_USER="tacov2"

cd "$BASE"
# Der VPS hat nie eigene Änderungen; lokale Abweichungen (z. B. ein Build) werden verworfen
sudo -u "$SVC_USER" git fetch origin main
sudo -u "$SVC_USER" git reset --hard origin/main
echo "== Bot-Abhängigkeiten"
sudo -u "$SVC_USER" bash -c "cd $BASE/bot && npm install --omit=dev --no-audit --no-fund 2>&1 | tail -2"
echo "== Datenbank-Treiber"
sudo -u "$SVC_USER" bash -c "cd '$BASE/server/resources/[tacov]/tacov_db' && npm install --omit=dev --no-audit --no-fund 2>&1 | tail -2"
[ -d "$BASE/server/resources/[tacov]/tacov_db/node_modules/mysql2" ] || { echo "FEHLER: mysql2 wurde nicht installiert."; exit 1; }
# Alte Fremd-Resource und Reste alter Ordnernamen entfernen (Resources heißen tacov_<name>)
rm -rf "$BASE/server/resources/[external]"
for old in db core state crime civ; do
  [ -d "$BASE/server/resources/[tacov]/$old" ] && [ ! -f "$BASE/server/resources/[tacov]/$old/fxmanifest.lua" ] && rm -rf "$BASE/server/resources/[tacov]/$old"
done
sed -i '/^ensure oxmysql/d' "$BASE/server/server.cfg"

if [ -d "$BASE/ui" ] && [ -f "$BASE/ui/package.json" ]; then
  echo "== UI bauen"
  sudo -u "$SVC_USER" bash -c "cd $BASE/ui && npm install --no-audit --no-fund 2>&1 | tail -1 && npm run build 2>&1 | tail -3"
fi

systemctl restart tacov2-bot
systemctl restart tacov2-server
echo "Deploy abgeschlossen: $(git -C "$BASE" log --oneline -1)"
