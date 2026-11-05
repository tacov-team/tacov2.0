#!/usr/bin/env bash
# TacoV · Neuen Stand von main einspielen und Dienste neu starten. Als root oder tacov ausführen.
set -euo pipefail
BASE="/opt/tacov2"
SVC_USER="tacov2"

cd "$BASE"
sudo -u "$SVC_USER" git pull --ff-only
sudo -u "$SVC_USER" bash -c "cd $BASE/bot && npm install --omit=dev --no-audit --no-fund >/dev/null"

if [ -d "$BASE/ui" ] && [ -f "$BASE/ui/package.json" ]; then
  sudo -u "$SVC_USER" bash -c "cd $BASE/ui && npm install --no-audit --no-fund >/dev/null && npm run build"
fi

systemctl restart tacov2-bot
systemctl restart tacov2-server
echo "Deploy abgeschlossen: $(git -C "$BASE" log --oneline -1)"
