# Entwicklung

## Lokale Umgebung

Benötigt: FiveM-Server-Artefakte (aktueller Recommended-Build), MariaDB 11 mit phpMyAdmin als Weboberfläche, Node 20, Git.

1. `server/server.cfg.example` nach `server/server.cfg` kopieren und Lizenzschlüssel sowie Datenbankzugang eintragen (`server.cfg` ist in `.gitignore`).
2. Datenbank anlegen: `tacov`, Nutzer mit Vollzugriff; Migrationen laufen beim ersten Start des Kerns.
   oxmysql (https://github.com/overextended/oxmysql, Release-Zip) nach `server/resources/[external]/oxmysql` entpacken; der Ordner ist nicht im Repository.
3. UI: `cd ui && npm install && npm run build` – der Build landet in `server/resources/[tacov]/core/ui/`.
4. Server starten: `FXServer +exec server.cfg` im Ordner `server/`.
5. Bot: `cd bot && cp .env.example .env` ausfüllen, `npm install && npm start` (siehe `bot/README.md`).

## Prüfungen vor dem Commit
`bash tools/ci/check_structure.sh`, `bash tools/ci/check_secrets.sh`, `luacheck server/resources`, `cd bot && npm run check`.

## VPS

Einmalig als root: `bash tools/vps/setup.sh` (Ubuntu 22.04/24.04, Debian 12). Legt Nutzer `tacov2`, `/opt/tacov2`, Datenbank `tacov2`, MariaDB + phpMyAdmin (Basic-Auth), Node 20, FXServer (Port 30121), oxmysql und die Dienste `tacov2-server` / `tacov2-bot` an – alles getrennt vom bestehenden `tacov`-Ordner auf dem VPS. Danach Lizenzschlüssel in `server/server.cfg` und Token in `bot/.env` eintragen.

Updates: `bash /opt/tacov2/tools/vps/deploy.sh` – zieht `main`, baut UI und Bot, startet die Dienste neu. Konfigurationen mit Geheimnissen (`server.cfg`, `.env`) liegen nur auf dem VPS und nie im Repository.

## Branching

- `main`: immer spielbar
- `modul/<name>`: ein Branch je Modul
- Tags `welle-A` … `welle-D`, `season-1` …
- Hotfix: Branch von `main`, Tag nach dem Merge

## Definition of Done je Modul

1. Config: alle Spielwerte in der Modul-Config, von der CI geprüft
2. Server entscheidet: Geld, Items, Waffen nur über den Kern mit Journal-Eintrag
3. Oberfläche entspricht dem abgenommenen Entwurf; Zustände Fehler, leer, Laden, gesperrt umgesetzt
4. Logs in der passenden Kategorie und im Discord-Kanal
5. Tests für Berechnungen plus Testprotokoll vom Testserver
6. Abschnitt in `docs/module/<name>.md`
7. Review durch ein zweites Augenpaar
