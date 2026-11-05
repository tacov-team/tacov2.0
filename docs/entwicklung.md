# Entwicklung

## Lokale Umgebung

Benötigt: FiveM-Server-Artefakte (aktueller Recommended-Build), MariaDB 11, Node 20, Git.

1. `server/server.cfg.example` nach `server/server.cfg` kopieren und Lizenzschlüssel sowie Datenbankzugang eintragen (`server.cfg` ist in `.gitignore`).
2. Datenbank anlegen: `tacov`, Nutzer mit Vollzugriff; Migrationen laufen beim ersten Start des Kerns.
3. UI: `cd ui && npm install && npm run build` – der Build landet in `server/resources/[tacov]/core/ui/`.
4. Server starten: `FXServer +exec server.cfg` im Ordner `server/`.

## Deploy auf den VPS

Der VPS zieht `main` per `git pull` und startet den Server neu. Konfigurationen mit Geheimnissen (`server.cfg`, `.env`) liegen nur auf dem VPS und nie im Repository.

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
