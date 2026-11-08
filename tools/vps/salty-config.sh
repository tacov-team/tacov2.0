#!/usr/bin/env bash
# TacoV · SaltyChat-Konfiguration (config.json) auf Live- und Testserver an unsere Tasten und Sprechweiten anpassen.
#   - VoiceRanges 3/10/25 m (Konzept 5.5), keine eigene Benachrichtigung (HUD übernimmt)
#   - ToggleRange und TalkMegaphone ohne Standardtaste: Sprechweite läuft über unser Z (ruft +voiceRange), Megafon über Alt;
#     SaltyChats Standard F1 würde sonst mit dem Handy kollidieren
#   - Funk-Sprechtasten bleiben bei SaltyChat (N primär, Feststelltaste sekundär)
# Als root ausführen; danach beide Server neu starten (deploy.sh / deploy-test.sh).
set -euo pipefail
for BASE in /opt/tacov2 /opt/tacov2-test; do
  CFG="$BASE/server/resources/[external]/saltychat/config.json"
  [ -f "$CFG" ] || { echo "übersprungen: $CFG fehlt"; continue; }
  python3 - "$CFG" <<'PY'
import json, sys
path = sys.argv[1]
cfg = json.load(open(path))
cfg.update({
  'VoiceRanges': [3.0, 10.0, 25.0], 'EnableVoiceRangeNotification': False,
  'ToggleRange': '', 'TalkMegaphone': '', 'TalkPrimary': 'N', 'TalkSecondary': 'CAPITAL',
  'MegaphoneRange': 60.0, 'EnableRadioHardcoreMode': False, 'RadioType': 4,
})
json.dump(cfg, open(path, 'w'), indent=2); open(path, 'a').write('\n')
print('angepasst:', path)
PY
done
