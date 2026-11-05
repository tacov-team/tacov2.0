#!/usr/bin/env bash
# TacoV · Neuen Stand von main einspielen und Dienste neu starten. Als root oder tacov ausführen.
set -euo pipefail
BASE="/opt/tacov"

cd "$BASE"
sudo -u tacov git pull --ff-only
sudo -u tacov bash -c "cd $BASE/bot && npm install --omit=dev --no-audit --no-fund >/dev/null"

if [ -d "$BASE/ui" ] && [ -f "$BASE/ui/package.json" ]; then
  sudo -u tacov bash -c "cd $BASE/ui && npm install --no-audit --no-fund >/dev/null && npm run build"
fi

systemctl restart tacov-bot
systemctl restart tacov-server
echo "Deploy abgeschlossen: $(git -C "$BASE" log --oneline -1)"
