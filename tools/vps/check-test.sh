#!/usr/bin/env bash
# TacoV · Schnellprüfung des Testservers (Punkt 1.8): lauscht er, ist die Firewall offen, was sagt die Konsole?
BASE="/opt/tacov2-test"
echo "== Dienst";       systemctl is-active tacov2-test-server
echo "== Ports (30122 muss hier stehen)"; ss -lunp 2>/dev/null | grep -E ':3012[0-9]' || echo "kein Port 3012x offen (UDP)"
ss -ltnp 2>/dev/null | grep -E ':3012[0-9]' || echo "kein Port 3012x offen (TCP)"
echo "== Firewall";     ufw status 2>/dev/null | grep -E '3012|Status' || echo "ufw nicht aktiv"
echo "== server.cfg";   grep -E '^(endpoint_add|sv_licenseKey|set tacov_db)' "$BASE/server/server.cfg" | sed -E 's#(mysql://[^:]+:)[^@]+@#\1***@#; s#(sv_licenseKey ")[^"]{6}[^"]*#\1******#'
echo "== Letzte Konsolenzeilen"; sudo -u tacov2 screen -S tacov2-test -X hardcopy /tmp/tacov2-test.txt 2>/dev/null; tail -n 25 /tmp/tacov2-test.txt 2>/dev/null | sed '/^$/d' || echo "keine screen-Sitzung"
