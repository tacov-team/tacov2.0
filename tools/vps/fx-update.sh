#!/usr/bin/env bash
# TacoV · FXServer-Build installieren oder wechseln. Als root ausführen.
#   bash fx-update.sh              -> Recommended-Build (Standard)
#   bash fx-update.sh latest       -> neuester Build
#   bash fx-update.sh 12345-abc... -> bestimmter Ordnername von der Artefakt-Seite
set -euo pipefail
BASE="/opt/tacov2"
SVC_USER="tacov2"
API="https://changelogs-live.fivem.net/api/changelog/versions/linux/server"
ARTIFACTS="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master"
WANT="${1:-recommended}"

case "$WANT" in
  recommended|latest)
    JSON="$(curl -fsSL "$API")"
    URL="$(printf '%s' "$JSON" | grep -o "\"${WANT}_download\":\"[^\"]*\"" | cut -d'"' -f4)"
    VER="$(printf '%s' "$JSON" | grep -o "\"${WANT}\":\"[0-9]*\"" | cut -d'"' -f4)"
    ;;
  *)
    URL="$ARTIFACTS/$WANT/fx.tar.xz"
    VER="$WANT"
    ;;
esac
if [ -z "${URL:-}" ]; then echo "Build-Adresse konnte nicht ermittelt werden."; exit 1; fi

echo "Installiere FXServer $VER ($WANT) ..."
curl -fsSL "$URL" -o /tmp/fx.tar.xz
WAS_ACTIVE=0
systemctl is-active --quiet tacov2-server && WAS_ACTIVE=1
[ "$WAS_ACTIVE" -eq 1 ] && systemctl stop tacov2-server
rm -rf "$BASE/fx.new" && mkdir -p "$BASE/fx.new"
tar -xf /tmp/fx.tar.xz -C "$BASE/fx.new"
rm -f /tmp/fx.tar.xz
[ -d "$BASE/fx" ] && rm -rf "$BASE/fx.old" && mv "$BASE/fx" "$BASE/fx.old"
mv "$BASE/fx.new" "$BASE/fx"
echo "$VER" > "$BASE/fx/.tacov-build"
chown -R "$SVC_USER:$SVC_USER" "$BASE/fx"
[ "$WAS_ACTIVE" -eq 1 ] && systemctl start tacov2-server
echo "FXServer $VER installiert (vorherige Version liegt in $BASE/fx.old)."
