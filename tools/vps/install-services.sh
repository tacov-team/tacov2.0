#!/usr/bin/env bash
# TacoV · systemd-Dienste anlegen/erneuern. Als root ausführen. Wird von setup.sh aufgerufen.
# FXServer braucht eine Konsole und stürzt ohne ab; darum läuft er in einer screen-Sitzung.
#   Konsole öffnen:  sudo -u tacov2 screen -r tacov2      (verlassen mit Strg+A, dann D)
set -euo pipefail
BASE="/opt/tacov2"
SVC_USER="tacov2"

command -v screen >/dev/null || { apt-get update -qq; apt-get install -y -qq screen; }

cat > /etc/systemd/system/tacov2-server.service <<EOF
[Unit]
Description=TacoV FXServer
After=network.target mariadb.service

[Service]
Type=simple
User=$SVC_USER
WorkingDirectory=$BASE/server
ExecStart=/usr/bin/screen -DmS tacov2 $BASE/fx/run.sh +exec server.cfg
ExecStop=/usr/bin/screen -S tacov2 -X stuff "quit\\n"
TimeoutStopSec=20
KillMode=control-group
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/tacov2-bot.service <<EOF
[Unit]
Description=TacoV Discord-Bot
After=network.target mariadb.service

[Service]
User=$SVC_USER
WorkingDirectory=$BASE/bot
ExecStart=/usr/bin/node src/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tacov2-server tacov2-bot >/dev/null
echo "Dienste tacov2-server und tacov2-bot eingerichtet."
