#!/usr/bin/env bash
# TacoV · Gekaufte Map-Resources (MLOs) und SaltyChat vom Live- auf den Testserver kopieren. Als root ausführen.
#   Kopiert /opt/tacov2/server/resources/[kauf] und [external] nach /opt/tacov2-test, ohne Duplikate (saltychat in [kauf])
#   und ohne dpemotes (braucht mysql-async, das es bei uns nicht gibt). Trägt `ensure [kauf]` und `ensure saltychat` in die
#   Test-server.cfg ein und startet den Testserver neu.
set -euo pipefail
LIVE="/opt/tacov2/server/resources"
TEST="/opt/tacov2-test/server/resources"
CFG="/opt/tacov2-test/server/server.cfg"
SVC_USER="tacov2"

command -v rsync >/dev/null || { apt-get update -qq; apt-get install -y -qq rsync; }
[ -d "$LIVE/[kauf]" ] || { echo "Auf dem Live-Server gibt es keinen Ordner [kauf]."; exit 1; }

echo "== MLOs ([kauf])"
rsync -a --delete --exclude 'saltychat' --exclude 'dpemotes-master' "$LIVE/[kauf]/" "$TEST/[kauf]/"
echo "== SaltyChat ([external])"
if [ -d "$LIVE/[external]/saltychat" ]; then rsync -a --delete "$LIVE/[external]/" "$TEST/[external]/"; fi
chown -R "$SVC_USER:$SVC_USER" "$TEST/[kauf]" "$TEST/[external]" 2>/dev/null || true

grep -q '^ensure \[kauf\]' "$CFG" || printf '\n# Gekaufte Map-Resources (nur Stream-Daten, kein Code)\nensure [kauf]\n' >> "$CFG"
if [ -d "$TEST/[external]/saltychat" ]; then grep -q '^ensure saltychat' "$CFG" || printf 'ensure saltychat\n' >> "$CFG"; fi

systemctl restart tacov2-test-server
echo "Kopiert: $(ls "$TEST/[kauf]" | tr '\n' ' ')"
echo "Testserver neu gestartet."
