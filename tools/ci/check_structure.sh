#!/usr/bin/env bash
# Prüft, dass die Grundstruktur des Repositories vorhanden ist.
set -euo pipefail

required=(
  "README.md"
  "docs/entscheidungen.md"
  "docs/entwicklung.md"
  "server/server.cfg.example"
  "server/resources/[tacov]/core"
  "server/resources/[tacov]/state"
  "server/resources/[tacov]/crime"
  "server/resources/[tacov]/civ"
  "server/resources/[tacov]/db"
  "ui"
  "bot"
)

fail=0
for p in "${required[@]}"; do
  if [ ! -e "$p" ]; then
    echo "FEHLT: $p"
    fail=1
  fi
done

# Jede Resource braucht ein fxmanifest.lua (leere Ordner sind erlaubt, solange nichts drin ist)
while IFS= read -r -d '' manifest_dir; do
  if [ -n "$(ls -A "$manifest_dir" 2>/dev/null | grep -v '^\.gitkeep$')" ] && [ ! -f "$manifest_dir/fxmanifest.lua" ]; then
    echo "FEHLT: $manifest_dir/fxmanifest.lua"
    fail=1
  fi
done < <(find "server/resources/[tacov]" -mindepth 1 -maxdepth 1 -type d -print0)

if [ "$fail" -ne 0 ]; then
  echo "Strukturprüfung fehlgeschlagen."
  exit 1
fi
echo "Struktur in Ordnung."
