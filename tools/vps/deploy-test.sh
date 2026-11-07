#!/usr/bin/env bash
# TacoV · Testserver auf den Stand von develop bringen und neu starten (Punkt 1.8). Als root ausführen.
set -euo pipefail
BASE="/opt/tacov2-test"
SVC_USER="tacov2"
cd "$BASE"
sudo -u "$SVC_USER" git fetch origin develop
sudo -u "$SVC_USER" git reset --hard origin/develop
sudo -u "$SVC_USER" bash -c "cd '$BASE/server/resources/[tacov]/tacov_db' && npm install --omit=dev --no-audit --no-fund 2>&1 | tail -1"
if [ -f "$BASE/ui/package.json" ]; then
  sudo -u "$SVC_USER" bash -c "cd $BASE/ui && npm install --no-audit --no-fund 2>&1 | tail -1 && npm run build 2>&1 | tail -1"
fi
printf '{"version":"%s-test","deployed":"%s"}\n' "$(git -C "$BASE" rev-parse --short HEAD)" "$(date -Iseconds)" \
  | sudo -u "$SVC_USER" tee "$BASE/server/resources/[tacov]/tacov_core/version.json" >/dev/null
systemctl restart tacov2-test-server
echo "Testserver: $(git -C "$BASE" log --oneline -1)"
