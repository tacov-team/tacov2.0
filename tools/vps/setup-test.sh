#!/usr/bin/env bash
# TacoV · Testserver einrichten (Punkt 1.8): zweite Instanz auf demselben VPS, als root ausführen.
#   /opt/tacov2-test, Branch develop, Datenbank tacov2_test, Port 30122, Dienst tacov2-test-server (screen tacov2-test).
#   Kein eigener Bot: der Testserver schreibt in seine eigene Datenbank, Discord bleibt dem Live-Server vorbehalten.
#   FXServer-Artefakte werden vom Live-Server geteilt (/opt/tacov2/fx).
set -euo pipefail
LIVE="/opt/tacov2"
BASE="/opt/tacov2-test"
SVC_USER="tacov2"
DB_NAME="tacov2_test"
DB_USER="tacov2_test"
PORT=30122
REPO="https://github.com/tacov-team/tacov2.0.git"

if [ "$(id -u)" -ne 0 ]; then echo "Bitte als root ausführen."; exit 1; fi
[ -x "$LIVE/fx/run.sh" ] || { echo "Live-Server unter $LIVE fehlt (setup.sh zuerst)."; exit 1; }

echo "== 1/5 Repository (develop)"
mkdir -p "$BASE"; chown "$SVC_USER:$SVC_USER" "$BASE"
if [ ! -d "$BASE/.git" ]; then
  sudo -u "$SVC_USER" git clone -b develop "$REPO" "$BASE"
else
  sudo -u "$SVC_USER" git -C "$BASE" fetch origin develop
  sudo -u "$SVC_USER" git -C "$BASE" reset --hard origin/develop
fi
[ -e "$BASE/fx" ] || ln -s "$LIVE/fx" "$BASE/fx"

echo "== 2/5 Datenbank $DB_NAME"
if [ -f "$BASE/.db_pass" ]; then DB_PASS="$(cat "$BASE/.db_pass")"; else
DB_PASS="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | cut -c1-24)"
fi
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"
install -m 600 -o "$SVC_USER" -g "$SVC_USER" /dev/null "$BASE/.db_pass"
echo "$DB_PASS" > "$BASE/.db_pass"
# Whitelist vom Live-Server übernehmen, damit dieselben Leute auf den Testserver können
mysql "$DB_NAME" -e "CREATE TABLE IF NOT EXISTS whitelist LIKE \`tacov2\`.whitelist; INSERT IGNORE INTO whitelist SELECT * FROM \`tacov2\`.whitelist;" 2>/dev/null || true

echo "== 3/5 Datenbank-Treiber"
sudo -u "$SVC_USER" bash -c "cd '$BASE/server/resources/[tacov]/tacov_db' && npm install --omit=dev --no-audit --no-fund >/dev/null"

echo "== 4/5 server.cfg (vom Live-Server abgeleitet)"
if [ ! -f "$BASE/server/server.cfg" ]; then
  sed -e "s#0.0.0.0:30121#0.0.0.0:${PORT}#g" \
      -e "s#^set tacov_db .*#set tacov_db \"mysql://${DB_USER}:${DB_PASS}@127.0.0.1:3306/${DB_NAME}\"#" \
      -e "s#^sv_hostname .*#sv_hostname \"[TEST] TacoV | Entwicklung\"#" \
      -e "s#^sets sv_projectName .*#sets sv_projectName \"TacoV Test\"#" \
      -e "s#^sv_licenseKey .*#sv_licenseKey \"HIER_EINTRAGEN\"#" \
      "$LIVE/server/server.cfg" > "$BASE/server/server.cfg"
  chown "$SVC_USER:$SVC_USER" "$BASE/server/server.cfg"; chmod 600 "$BASE/server/server.cfg"
fi

echo "== 5/5 Dienst tacov2-test-server"
cat > /etc/systemd/system/tacov2-test-server.service <<UNIT
[Unit]
Description=TacoV FXServer (Test)
After=network.target mariadb.service

[Service]
Type=simple
User=$SVC_USER
WorkingDirectory=$BASE/server
ExecStart=/usr/bin/screen -DmS tacov2-test $BASE/fx/run.sh +exec server.cfg
ExecStop=/usr/bin/screen -S tacov2-test -X stuff "quit\\n"
TimeoutStopSec=20
KillMode=control-group
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable tacov2-test-server >/dev/null
ufw allow ${PORT}/tcp >/dev/null; ufw allow ${PORT}/udp >/dev/null
chown -R "$SVC_USER:$SVC_USER" "$BASE"

cat <<EOT
Testserver eingerichtet. Noch von Hand:
  1. Zweiten Schlüssel auf keymaster.fivem.net anlegen (gleiche IP, Port ${PORT}) und in $BASE/server/server.cfg bei sv_licenseKey eintragen
  2. systemctl start tacov2-test-server     Konsole: sudo -u tacov2 screen -r tacov2-test (verlassen: Strg+A, D)
Updates einspielen (Branch develop): bash $BASE/tools/vps/deploy-test.sh
Im Spiel verbinden: connect <server-ip>:${PORT}
EOT
