#!/usr/bin/env bash
# TacoV · TeamSpeak-3-Server und SaltyChat einrichten (Punkt 1.10). Als root ausführen.
#   - TeamSpeak 3 Server unter /opt/teamspeak (Nutzer teamspeak), Dienst teamspeak3, Ports 9987/udp, 30033/tcp
#   - Kanäle „TacoV Ingame“ (Passwort), „Lobby“, „Support 1/2“ per ServerQuery
#   - SaltyChat-Resource (Fremdcode, Ausnahme laut Punkt 0.14) nach server/resources/[external]/saltychat mit config.json
# Danach von Hand: Non-Profit-Lizenz bei TeamSpeak, Server-Kennung bei SaltyChat (saltmine.de) freischalten lassen.
set -euo pipefail
TS_VERSION="${TS_VERSION:-3.13.7}"
TS_DIR="/opt/teamspeak"
TS_USER="teamspeak"
BASE="/opt/tacov2"
SVC_USER="tacov2"
EXT="$BASE/server/resources/[external]"
SALTY_VERSION="${SALTY_VERSION:-latest}"

if [ "$(id -u)" -ne 0 ]; then echo "Bitte als root ausführen."; exit 1; fi
apt-get install -y -qq bzip2 curl unzip python3 >/dev/null

echo "== 1/4 TeamSpeak 3 Server $TS_VERSION"
id "$TS_USER" >/dev/null 2>&1 || useradd -r -m -d "$TS_DIR" -s /usr/sbin/nologin "$TS_USER"
mkdir -p "$TS_DIR"
if [ ! -x "$TS_DIR/ts3server" ]; then
  tmp=$(mktemp -d)
  curl -fsSL "https://files.teamspeak-services.com/releases/server/${TS_VERSION}/teamspeak3-server_linux_amd64-${TS_VERSION}.tar.bz2" -o "$tmp/ts3.tar.bz2"
  tar -xjf "$tmp/ts3.tar.bz2" -C "$tmp"
  cp -r "$tmp"/teamspeak3-server_linux_amd64/. "$TS_DIR"/
  rm -rf "$tmp"
fi
touch "$TS_DIR/.ts3server_license_accepted"
chown -R "$TS_USER:$TS_USER" "$TS_DIR"
cat > /etc/systemd/system/teamspeak3.service <<UNIT
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
User=$TS_USER
WorkingDirectory=$TS_DIR
Environment=TS3SERVER_LICENSE=accept
ExecStart=$TS_DIR/ts3server_minimal_runscript.sh query_ip_allowlist=query_ip_allowlist.txt
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
printf '127.0.0.1\n::1\n' > "$TS_DIR/query_ip_allowlist.txt"; chown "$TS_USER:$TS_USER" "$TS_DIR/query_ip_allowlist.txt"
systemctl daemon-reload
systemctl enable --now teamspeak3 >/dev/null
ufw allow 9987/udp >/dev/null; ufw allow 30033/tcp >/dev/null
sleep 6

echo "== 2/4 ServerQuery: Zugang und Kanäle"
# Läuft der Server?
for _ in 1 2 3 4 5 6; do systemctl is-active --quiet teamspeak3 && break; sleep 2; done
if ! systemctl is-active --quiet teamspeak3; then
  echo "TeamSpeak-Dienst läuft nicht. Letzte Meldungen:"; journalctl -u teamspeak3 -n 30 --no-pager -o cat; exit 1
fi
# Beim ersten Start stehen serveradmin-Passwort und Admin-Token im Log (Datei und journald); wir merken sie uns in $TS_DIR/.query
if [ ! -f "$TS_DIR/.query" ]; then
  qpass=""; token=""
  for _ in $(seq 1 15); do
    all=$( { cat "$TS_DIR"/logs/*.log 2>/dev/null; journalctl -u teamspeak3 --no-pager -o cat 2>/dev/null; } || true)
    qpass=$(printf '%s' "$all" | grep -o 'password= *"[^"]*"' | head -1 | sed 's/password= *"//;s/"$//' || true)
    token=$(printf '%s' "$all" | grep -o 'token=[A-Za-z0-9+/=]*' | head -1 | sed 's/token=//' || true)
    [ -n "$qpass" ] && break
    sleep 2
  done
  if [ -z "$qpass" ]; then
    echo "ServerQuery-Passwort nicht gefunden. Entweder lief der Server schon einmal (dann steht es im ersten Log unter $TS_DIR/logs)"
    echo "oder der Start ist fehlgeschlagen. Letzte Meldungen:"; journalctl -u teamspeak3 -n 30 --no-pager -o cat
    echo "Manuell: printf 'QUERY_PASS=<Passwort>\\nADMIN_TOKEN=<Token>\\n' > $TS_DIR/.query && chmod 600 $TS_DIR/.query, dann Skript erneut starten."
    exit 1
  fi
  install -m 600 /dev/null "$TS_DIR/.query"
  printf 'QUERY_PASS=%s\nADMIN_TOKEN=%s\n' "$qpass" "$token" > "$TS_DIR/.query"
fi
# shellcheck disable=SC1090
. "$TS_DIR/.query"
INGAME_PASS="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | cut -c1-12)"
[ -f "$TS_DIR/.ingame_pass" ] && INGAME_PASS="$(cat "$TS_DIR/.ingame_pass")"
install -m 600 /dev/null "$TS_DIR/.ingame_pass"; echo "$INGAME_PASS" > "$TS_DIR/.ingame_pass"

python3 - "$QUERY_PASS" "$INGAME_PASS" > "$TS_DIR/.channels" <<'PY'
import socket, sys, re
qpass, ingame = sys.argv[1], sys.argv[2]
def esc(s): return s.replace('\\','\\\\').replace('/','\\/').replace(' ','\\s').replace('|','\\p')
s = socket.create_connection(('127.0.0.1', 10011), timeout=10)
f = s.makefile('rw', newline='\n')
def cmd(c):
    f.write(c + '\n'); f.flush()
    out = ''
    while True:
        line = f.readline().lstrip('\r')  # ServerQuery beendet Zeilen mit \n\r
        if not line: raise SystemExit('ServerQuery: Verbindung beendet bei ' + c)
        out += line
        if line.startswith('error id='):
            if 'id=0 ' not in line and 'id=0\n' not in line: raise SystemExit('ServerQuery: ' + line.strip() + ' bei ' + c)
            return out
f.readline(); f.readline()  # Banner: TS3 / Welcome
cmd('login serveradmin ' + esc(qpass))
cmd('use sid=1')
cmd('serveredit virtualserver_name=' + esc('TacoV Roleplay') + ' virtualserver_welcomemessage=' + esc('Willkommen bei TacoV. Im Spiel wirst du automatisch in den Ingame-Kanal verschoben.'))
existing = cmd('channellist')
def ensure(name, extra=''):
    m = re.search(r'cid=(\d+) pid=\d+ channel_order=\d+ channel_name=' + re.escape(esc(name)) + r'(?:\s|$)', existing)
    if m: return m.group(1)
    r = cmd('channelcreate channel_name=' + esc(name) + ' channel_flag_permanent=1 ' + extra)
    return re.search(r'cid=(\d+)', r).group(1)
lobby = ensure('Lobby', 'channel_flag_default=1')
ingame_id = ensure('TacoV Ingame', 'channel_password=' + esc(ingame) + ' channel_codec=4 channel_codec_quality=10 channel_maxclients=-1')
s1 = ensure('Support 1'); s2 = ensure('Support 2')
uid = re.search(r'virtualserver_unique_identifier=(\S+)', cmd('serverinfo')).group(1).replace('\\/','/')
print(f'INGAME_ID={ingame_id}\nSWISS_IDS={s1},{s2}\nSERVER_UID={uid}')
cmd('quit')
PY
# shellcheck disable=SC1090
. "$TS_DIR/.channels"

echo "== 3/4 SaltyChat-Resource"
mkdir -p "$EXT"
if [ ! -f "$EXT/saltychat/fxmanifest.lua" ]; then
  tmp=$(mktemp -d)
  if [ "$SALTY_VERSION" = "latest" ]; then
    url=$(curl -fsSL https://api.github.com/repos/saltminede/saltychat-fivem/releases/latest | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | sed 's/.*"\(http[^"]*\)"/\1/')
  else
    url="https://github.com/saltminede/saltychat-fivem/releases/download/${SALTY_VERSION}/saltychat-fivem.zip"
  fi
  [ -n "$url" ] || { echo "Kein SaltyChat-Release gefunden – bitte Zip von github.com/saltminede/saltychat-fivem/releases nach $EXT entpacken."; exit 1; }
  curl -fsSL "$url" -o "$tmp/salty.zip"
  # Das Release-Zip stammt von Windows (Backslash-Pfade); Python entpackt es mit normalisierten Pfaden
  python3 - "$tmp/salty.zip" "$tmp/x" <<'PY'
import sys, zipfile, os
zip_path, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path) as z:
    for info in z.infolist():
        name = info.filename.replace('\\', '/')
        if name.endswith('/') or not name: continue
        target = os.path.normpath(os.path.join(out, name))
        if not target.startswith(os.path.abspath(out)): continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with z.open(info) as f, open(target, 'wb') as o: o.write(f.read())
PY
  src=$(find "$tmp/x" -type f -name fxmanifest.lua -path '*saltychat/*' -print -quit)
  [ -n "$src" ] || src=$(find "$tmp/x" -type f -name fxmanifest.lua -print -quit)
  [ -n "$src" ] || { echo "Zip enthält keine saltychat-Resource."; ls -R "$tmp/x" | head -30; exit 1; }
  cp -r "$(dirname "$src")" "$EXT/saltychat"
  rm -rf "$tmp"
fi
python3 - "$EXT/saltychat/config.json" "$SERVER_UID" "$INGAME_ID" "$INGAME_PASS" "$SWISS_IDS" <<'PY'
import json, sys
path, uid, ingame, pw, swiss = sys.argv[1:6]
cfg = json.load(open(path))
cfg.update({
  'VoiceEnabled': True, 'ServerUniqueIdentifier': uid, 'IngameChannelId': int(ingame), 'IngameChannelPassword': pw,
  'SwissChannelIds': [int(x) for x in swiss.split(',') if x], 'VoiceRanges': [3.0, 10.0, 25.0],
  'EnableVoiceRangeNotification': False, 'NamePattern': '[{serverid}] {guid}', 'SoundPack': 'default',
  'RadioType': 4, 'EnableRadioHardcoreMode': False, 'MegaphoneRange': 60.0,
})
json.dump(cfg, open(path, 'w'), indent=2); open(path, 'a').write('\n')
PY
chown -R "$SVC_USER:$SVC_USER" "$EXT"
grep -q '^ensure saltychat' "$BASE/server/server.cfg" || printf '\n# Voice (Punkt 0.14): SaltyChat als einzige Fremd-Resource\nensure saltychat\n' >> "$BASE/server/server.cfg"

echo "== 4/4 Fertig"
cat <<EOT
TeamSpeak 3 läuft (Port 9987). Kanäle: Lobby (Standard), TacoV Ingame (Passwort gesetzt), Support 1/2.
Server-Kennung (für SaltyChat-Freischaltung): $SERVER_UID
Admin-Token zum Einlösen im TeamSpeak-Client (einmalig): $ADMIN_TOKEN
Noch von Hand:
  1. Non-Profit-Lizenz bei teamspeak.com beantragen und als licensekey.dat nach $TS_DIR legen, dann: systemctl restart teamspeak3
  2. Server-Kennung oben bei SaltyChat (saltmine.de) für den Server freischalten lassen
  3. Spieler: TeamSpeak 3 + SaltyChat-Plugin installieren, mit <server-ip> verbinden
  4. systemctl restart tacov2-server  (lädt die Resource saltychat)
EOT
