#!/usr/bin/env bash
# TacoV · Einmalige Einrichtung des VPS (Ubuntu 22.04/24.04 oder Debian 12), als root ausführen.
#
#   curl -fsSL https://raw.githubusercontent.com/tacov-team/tacov2.0/main/tools/vps/setup.sh -o setup.sh
#   bash setup.sh
#
# Legt an: Nutzer tacov2, /opt/tacov2 (Repo), MariaDB + phpMyAdmin, Node 20 + pm2, FXServer-Artefakte,
# Treiber der DB-Resource, systemd-Dienste tacov2-server und tacov2-bot. Fragt nur, was es nicht selbst erzeugen kann.
set -euo pipefail

REPO="https://github.com/tacov-team/tacov2.0.git"
BASE="/opt/tacov2"      # getrennt vom bestehenden tacov-Ordner
SVC_USER="tacov2"
DB_NAME="tacov2"
DB_USER="tacov2"

if [ "$(id -u)" -ne 0 ]; then echo "Bitte als root ausführen."; exit 1; fi

echo "== 1/8 Pakete"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl xz-utils ufw ca-certificates gnupg openssl mariadb-server
systemctl enable --now mariadb >/dev/null

echo "== 2/8 Nutzer und Ordner"
id "$SVC_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$SVC_USER"
mkdir -p "$BASE"
chown "$SVC_USER:$SVC_USER" "$BASE"

echo "== 3/8 Repository"
if [ ! -d "$BASE/.git" ]; then
  sudo -u "$SVC_USER" git clone "$REPO" "$BASE"
else
  sudo -u "$SVC_USER" git -C "$BASE" pull --ff-only
fi

echo "== 4/8 Datenbank"
if [ -f "$BASE/.db_pass" ]; then DB_PASS="$(cat "$BASE/.db_pass")"; else
DB_PASS="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | cut -c1-24)"
fi
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"
install -m 600 -o "$SVC_USER" -g "$SVC_USER" /dev/null "$BASE/.db_pass"
echo "$DB_PASS" > "$BASE/.db_pass"

echo "== 5/8 phpMyAdmin"
# apt-Variante mit Apache; nur per Basic-Auth erreichbar
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt-get install -y -qq phpmyadmin apache2-utils
touch /etc/phpmyadmin/.htpasswd
PMA_PASS="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | cut -c1-16)"
htpasswd -b /etc/phpmyadmin/.htpasswd tacov2 "$PMA_PASS" >/dev/null
cat > /etc/apache2/conf-available/phpmyadmin-auth.conf <<'EOF'
<Directory /usr/share/phpmyadmin>
    AuthType Basic
    AuthName "Datenbank"
    AuthUserFile /etc/phpmyadmin/.htpasswd
    Require valid-user
</Directory>
EOF
a2enconf phpmyadmin-auth >/dev/null
systemctl reload apache2
install -m 600 -o "$SVC_USER" -g "$SVC_USER" /dev/null "$BASE/.pma_pass"
echo "$PMA_PASS" > "$BASE/.pma_pass"

echo "== 6/8 Node 20 und pm2"
if ! command -v node >/dev/null || [ "$(node -v | cut -c2-3)" -lt 20 ]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null
  apt-get install -y -qq nodejs
fi
npm install -g pm2 >/dev/null 2>&1 || true

echo "== 7/8 FXServer und Datenbank-Treiber"
mkdir -p "$BASE/fx"
if [ ! -x "$BASE/fx/run.sh" ]; then
  bash "$BASE/tools/vps/fx-update.sh" recommended
fi
sudo -u "$SVC_USER" bash -c "cd '$BASE/server/resources/[tacov]/tacov_db' && npm install --omit=dev --no-audit --no-fund >/dev/null"
chown -R "$SVC_USER:$SVC_USER" "$BASE"

echo "== 8/8 Konfiguration und Dienste"
if [ ! -f "$BASE/server/server.cfg" ]; then
  sed -e "s#mysql://tacov:HIER_EINTRAGEN@127.0.0.1:3306/tacov#mysql://${DB_USER}:${DB_PASS}@127.0.0.1:3306/${DB_NAME}#" \
      -e "s#0.0.0.0:30120#0.0.0.0:30121#" \
      "$BASE/server/server.cfg.example" > "$BASE/server/server.cfg"
  chown "$SVC_USER:$SVC_USER" "$BASE/server/server.cfg"; chmod 600 "$BASE/server/server.cfg"
fi
if [ ! -f "$BASE/bot/.env" ]; then
  sed -e "s#^DB_PASS=.*#DB_PASS=${DB_PASS}#" -e "s#^DB_NAME=.*#DB_NAME=${DB_NAME}#" -e "s#^DB_USER=.*#DB_USER=${DB_USER}#" \
      "$BASE/bot/.env.example" > "$BASE/bot/.env"
  chown "$SVC_USER:$SVC_USER" "$BASE/bot/.env"; chmod 600 "$BASE/bot/.env"
fi
sudo -u "$SVC_USER" bash -c "cd $BASE/bot && npm install --omit=dev --no-audit --no-fund >/dev/null"

bash "$BASE/tools/vps/install-services.sh"

ufw allow OpenSSH >/dev/null
ufw allow 30121/tcp >/dev/null
ufw allow 30121/udp >/dev/null
ufw allow 80/tcp >/dev/null
ufw --force enable >/dev/null

cat <<EOF

Fertig. Jetzt noch von Hand:
  1. $BASE/server/server.cfg  -> sv_licenseKey (keymaster.fivem.net) eintragen
  2. $BASE/bot/.env           -> Discord-Token und IDs eintragen
  3. systemctl start tacov2-server tacov2-bot
     Konsole: sudo -u tacov2 screen -r tacov2 (verlassen: Strg+A, D)   /   Bot-Logs: journalctl -u tacov2-bot -f

phpMyAdmin: http://<server-ip>/phpmyadmin  (Web-Login tacov2, Passwort in $BASE/.pma_pass; DB-Login ${DB_USER}, Passwort in $BASE/.db_pass)
Updates einspielen: bash $BASE/tools/vps/deploy.sh
EOF
