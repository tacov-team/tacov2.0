#!/usr/bin/env bash
# Verhindert, dass Lizenzschlüssel, Passwörter oder Tokens eingecheckt werden.
set -euo pipefail

if [ -f server/server.cfg ]; then
  echo "server/server.cfg darf nicht im Repository liegen."
  exit 1
fi

patterns='sv_licenseKey "[A-Za-z0-9]{20,}"|tacov_db_pass "(?!HIER_EINTRAGEN)[^"]+"|(discord|bot)[_-]?token\s*[:=]\s*["'"'"']?[A-Za-z0-9._-]{30,}'
if git grep -nP -e "$patterns" -- ':!tools/ci/check_secrets.sh' >/dev/null 2>&1; then
  echo "Mögliches Geheimnis im Repository gefunden:"
  git grep -nP -e "$patterns" -- ':!tools/ci/check_secrets.sh'
  exit 1
fi
echo "Keine Geheimnisse gefunden."
