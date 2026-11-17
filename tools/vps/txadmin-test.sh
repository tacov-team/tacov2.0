#!/usr/bin/env bash
# TacoV · txAdmin auf dem Testserver ein- oder ausschalten. Als root ausführen.
#   bash tools/vps/txadmin-test.sh an    → Testserver startet über txAdmin (Weboberfläche auf Port 40121)
#   bash tools/vps/txadmin-test.sh aus   → zurück zum direkten Start (run.sh +exec server.cfg)
# txAdmin gehört zum FXServer-Artefakt (kein Zusatzdownload). Es verwaltet dann den Serverprozess; unsere Skripte
# (deploy-test.sh, sync-kauf.sh) funktionieren weiter, weil sie nur den Dienst tacov2-test-server neu starten.
# Der Live-Server bleibt unberührt.
set -euo pipefail
MODE="${1:-an}"
BASE="/opt/tacov2-test"
SVC_USER="tacov2"
UNIT="/etc/systemd/system/tacov2-test-server.service"
TXPORT=40121
TXDATA="$BASE/txData"

[ -x "$BASE/fx/run.sh" ] || { echo "Testserver unter $BASE fehlt (setup-test.sh zuerst)."; exit 1; }

if [ "$MODE" = "an" ]; then
  mkdir -p "$TXDATA"; chown -R "$SVC_USER:$SVC_USER" "$TXDATA"
  START="$BASE/fx/run.sh +set serverProfile tacov2test +set txAdminPort $TXPORT +set txDataPath $TXDATA"
  STOP=""
elif [ "$MODE" = "aus" ]; then
  START="$BASE/fx/run.sh +exec server.cfg"
  STOP='ExecStop=/usr/bin/screen -S tacov2-test -X stuff "quit\\n"'
else
  echo "Aufruf: $0 an|aus"; exit 1
fi

cat > "$UNIT" <<UNIT
[Unit]
Description=TacoV FXServer (Test)
After=network.target mariadb.service

[Service]
Type=simple
User=$SVC_USER
WorkingDirectory=$BASE/server
ExecStart=/usr/bin/screen -DmS tacov2-test $START
$STOP
TimeoutStopSec=20
KillMode=control-group
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl restart tacov2-test-server

if [ "$MODE" = "an" ]; then
  ufw allow ${TXPORT}/tcp >/dev/null 2>&1 || true
  IP=$(hostname -I | awk '{print $1}')
  cat <<MSG

txAdmin läuft für den Testserver.
  1. PIN ablesen:   sudo -u $SVC_USER screen -r tacov2-test     (verlassen: Strg+A, dann D)
  2. Im Browser:    http://$IP:$TXPORT   → PIN eingeben, mit dem cfx.re-Konto verknüpfen, Passwort setzen
  3. Einrichtung:   „Existing Server Data“ wählen
        Server Data Folder:  $BASE/server
        CFX File:            $BASE/server/server.cfg
     Danach „Save & Run Server“.
Zurück zum direkten Start:  bash $BASE/tools/vps/txadmin-test.sh aus
MSG
else
  echo "txAdmin ist aus – der Testserver startet wieder direkt mit server.cfg."
fi
