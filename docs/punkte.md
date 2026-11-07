# TacoV · Entwicklungspunkte

Stand: 07.11.2026. Der Phasenplan (`docs/phasenplan.md`) in einzelne Punkte zerlegt. **Ein Punkt = ein System**, wir arbeiten sie der Reihe nach ab, von vorn. Jeder Punkt wird erst „✅ abgenommen“, wenn der Betreiber ihn bestätigt hat – auch die bereits gebauten. Das Protokoll der Bestätigungen steht in `docs/entscheidungen.md`.

Status: ⬜ offen · 🔧 gebaut, noch nicht abgenommen · ✅ abgenommen · ⏸ zurückgestellt

## Phase 0 · Konzept und Grundentscheidungen

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 0.1 | Servername, Slots, Sprache, Setting | 🔧 | Name TacoV, 10 Slots, Deutsch, Los Santos Gegenwart |
| 0.2 | Leitbild und Grundsätze | 🔧 | Sechs Grundsätze (Konzept 1.1) |
| 0.3 | Weg zum Server (Discord, Whitelist) | 🔧 | Reaktion = Whitelist, Discord-ID als Anker |
| 0.4 | Einreise, Neulingspfad, Level/Probezeit | 🔧 | Einreise mit Teammitglied, Startgeld 5.000 $, Level 3/8/15 |
| 0.5 | Fraktionen zum Start und ihre Regeln | 🔧 | LSPD, LSMD, DMV, Regierung, DOJ, eine Streetgang; Caps |
| 0.6 | Wirtschaft: Geldkreislauf, Jobs, Bank, Steuern | 🔧 | 6 Jobs, Steuern 8 %, Kaufzeiten 10/40/80/200 h |
| 0.7 | Wirtschaft: Fahrzeuge, Immobilien, Firmen | 🔧 | Klassen, Garagen, Burger Shot |
| 0.8 | Verbrechen und Justiz | 🔧 | Drogen, Waffen, Raub, Strafkatalog, Haft, Koma |
| 0.9 | Alltag und Handy | 🔧 | Inventar, Bedürfnisse, 10 Apps, Interaktion, Läden |
| 0.10 | Items- und Orte-Tabellen | 🔧 | `docs/konzept/items.md`, `orte.md` |
| 0.11 | Team-Rollen und Rechte | ⬜ | Rollen im Detail, wer darf was (Frist 22.11.) |
| 0.12 | Anti-Cheat-Ansatz | ⬜ | eigener Abgleich oder zusätzlich kommerziell |
| 0.13 | Hoster, Testserver, Neustart-Fenster | ⬜ | |
| 0.14 | Voice (TeamSpeak-Plugin, Lizenz) | ⬜ | |
| 0.15 | Design-Richtung (V4: Gelb-Orange, Barlow, Listenmenüs) | 🔧 | `docs/design/README.md` |

## Phase 1 · Infrastruktur

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 1.1 | Repo, Branching, CI (luacheck, Struktur, Geheimnisse) | 🔧 | `tacov-team/tacov2.0`, `.github/workflows` |
| 1.2 | VPS-Einrichtung (`/opt/tacov2`, Nutzer, MariaDB, phpMyAdmin) | 🔧 | `tools/vps/setup.sh` |
| 1.3 | FXServer-Betrieb (screen, Dienste, Artefakt-Update, Deploy) | 🔧 | `deploy.sh`, `fx-update.sh` |
| 1.4 | Discord-Bot: Whitelist per Reaktion | 🔧 | `bot/` |
| 1.5 | Discord-Bot: Log-Spiegel (11 Kanäle) | 🔧 | |
| 1.6 | Geheimnisse und Zugänge (server.cfg, .env, CI-Prüfung) | 🔧 | |
| 1.7 | Backups und Monitoring | ⬜ | täglich, 14 Tage; Erreichbarkeit |

## Phase 2 · Kern (eigenes Framework)

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 2.1 | Datenbank-Resource `tacov_db` und `TacoV.DB` | 🔧 | mysql2 im FXServer-Node, Migrationen |
| 2.2 | Spieler und Verbindung (Discord-ID, Whitelist-Prüfung, Sperren) | 🔧 | |
| 2.3 | Charaktere (2 Plätze, Anlage, Auswahl, Autosave) | 🔧 | |
| 2.4 | Journal als einziger Geldweg, Konten | 🔧 | |
| 2.5 | Rechte und Rollen | 🔧 | |
| 2.6 | Logs (Kategorien, Spiegel in Discord) | 🔧 | |
| 2.7 | Befehlszeile (T) und Befehle | 🔧 | |
| 2.8 | Orte (Config + `/ort setzen`, Blips) | 🔧 | |
| 2.9 | Spielzeit, Level, Probezeit | 🔧 | |
| 2.10 | Tastenbelegung und Interaktion (E-Aufforderung, X-Rad, Listenmenü) | 🔧 | |

## Phase 3 · Alltag I

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 3.1 | Oberfläche V4: Grundlagen, Schriften, Panels | 🔧 | Schriftdateien fehlen noch (Betreiber) |
| 3.2 | HUD (Geld, Hunger/Durst, Funkliste, Infozeilen, Tacho) | 🔧 | |
| 3.3 | Hinweise (Toasts) | 🔧 | |
| 3.4 | Charakterauswahl | 🔧 | |
| 3.5 | Inventar (F2), Ablagen, Items, Icons | 🔧 | |
| 3.6 | Bedürfnisse Hunger/Durst | 🔧 | Fitness und Promille: Phase 5/10 |
| 3.7 | Hände hoch (H) | 🔧 | |
| 3.8 | Bank und Geldautomat | 🔧 | |
| 3.9 | Läden (24/7, LTD, Rob's, Baumarkt) | 🔧 | |

## Phase 4 · Fahrzeuge

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 4.1 | Fahrzeugklassen und Kaufliste | 🔧 | 8 Klassen, 52 Modelle |
| 4.2 | Kaufhäuser (PDM, LKW) mit Vorschau und Kamera | 🔧 | |
| 4.3 | Garagen (alle Parkplätze) und Garage-Ansicht | 🔧 | |
| 4.4 | Verwahrhof | 🔧 | |
| 4.5 | Schlüssel, Schloss, Schlüssel geben | 🔧 | |
| 4.6 | Kofferraum | 🔧 | |
| 4.7 | Tanken und Verbrauch, Tankstellenkarte | 🔧 | |
| 4.8 | Fahrzeugmenü (F6 → Fahrzeug, X-Rad) | 🔧 | |
| 4.9 | DMV: Zulassung, Halterwechsel | ⬜ | |
| 4.10 | Fahrschule: Theorie, Praxis, Führerschein A/B/C, Punkte | ⬜ | |
| 4.11 | NPC-Werkstatt: Reparatur, Upgrades, Zubehör | ⬜ | |
| 4.12 | Blitzer | ⬜ | |
| 4.13 | Kfz-Steuer | ⬜ | |
| 4.14 | Boote und Flugzeuge | ⏸ | Entscheidung später |

## Phase 5 · Charakter und Einstieg

| Nr. | Punkt | Status |
| --- | --- | --- |
| 5.1 | Charaktereditor (Gesicht, Haare, Farben) | ⬜ |
| 5.2 | Kleiderläden und Outfits | ⬜ |
| 5.3 | Friseur, Tattoo, Chirurg | ⬜ |
| 5.4 | Ladebildschirm und Einreise mit Teammitglied | ⬜ |
| 5.5 | Neulingspfad und Sozialwohnung (Grundlage) | ⬜ |
| 5.6 | Animationsmenü (F3) | ⬜ |
| 5.7 | Voice und Sprechweiten | ⬜ |
| 5.8 | Verletzungen und Erste Hilfe | ⬜ |
| 5.9 | Fitness und Promille | ⬜ |

## Phase 6 · Handy und Funk

| Nr. | Punkt | Status |
| --- | --- | --- |
| 6.1 | Handy-Item, Nummer, Grundgerüst der Oberfläche | ⬜ |
| 6.2 | Kontakte und Anrufe | ⬜ |
| 6.3 | Nachrichten (SMS, Standort, Gruppen) | ⬜ |
| 6.4 | Bank-App | ⬜ |
| 6.5 | Fahrzeuge-App | ⬜ |
| 6.6 | Einstellungen | ⬜ |
| 6.7 | Funkgerät und Funk-App, Funkliste im HUD | ⬜ |
| 6.8 | Notruf, Fraktion, Firma, Kamera, Feed | ⬜ (mit den jeweiligen Phasen) |

## Phase 7 · Jobs, Lohn, Steuern

| Nr. | Punkt | Status |
| --- | --- | --- |
| 7.1 | Jobcenter und Job-Grundgerüst (Anmelden, Firmenfahrzeug, Lohn) | ⬜ |
| 7.2 | Müllabfuhr | ⬜ |
| 7.3 | Lieferfahrer | ⬜ |
| 7.4 | Busfahrer | ⬜ |
| 7.5 | Taxi | ⬜ |
| 7.6 | Holzfäller | ⬜ |
| 7.7 | Bergbau | ⬜ |
| 7.8 | Payday, Einkommensteuer, Staatshaushalt | ⬜ |
| 7.9 | Kaufzeiten-Simulation in der CI | ⬜ |

## Phase 8 · Fraktionen

| Nr. | Punkt | Status |
| --- | --- | --- |
| 8.1 | Fraktionsmodul (Mitglieder, Ränge, Rechte, Kasse, Lager, Protokoll) | ⬜ |
| 8.2 | Dienst, Dienstkleidung, Fraktionsfahrzeuge | ⬜ |
| 8.3 | Fraktionsmenü (F6) vollständig | ⬜ |
| 8.4 | LSPD: MDT | ⬜ |
| 8.5 | LSPD: Dispatch und Notrufe | ⬜ |
| 8.6 | LSPD: Kontrolle, Beschlagnahme, Verhaftung | ⬜ |
| 8.7 | LSMD: Verletzungssystem, Krankenhaus, Rechnungen | ⬜ |
| 8.8 | DMV im Fraktionsbetrieb | ⬜ |
| 8.9 | Regierung: Rathaus, Bürgerbüro, Lizenzamt | ⬜ |
| 8.10 | DOJ: Gericht, Kaution, Verfahren | ⬜ |
| 8.11 | Streetgang: Ganghaus, Gebiete, Gangwar | ⬜ |

## Phase 9 · Immobilien und Firmen

| Nr. | Punkt | Status |
| --- | --- | --- |
| 9.1 | Immobilien: Typen, Kauf/Miete, Schlüssel, Lager | ⬜ |
| 9.2 | Sozialwohnung und Mietrückstand | ⬜ |
| 9.3 | Garagen an Immobilien | ⬜ |
| 9.4 | Möbelhaus | ⬜ |
| 9.5 | Firma Burger Shot | ⬜ |

## Phase 10 · Verbrechen und Justiz

| Nr. | Punkt | Status |
| --- | --- | --- |
| 10.1 | Drogen: Anbau, Herstellung, Verkauf, Wirkung | ⬜ |
| 10.2 | Waffen: Waffenschein, Kauf, Schwarzmarkt, Munition | ⬜ |
| 10.3 | Hehler und Schwarzgeldwäsche | ⬜ |
| 10.4 | Raub: Läden, Juwelier, Bank, Spieler | ⬜ |
| 10.5 | Strafkatalog, Geldstrafen, Punkte | ⬜ |
| 10.6 | Haft und Gefängnis | ⬜ |
| 10.7 | Koma, Tod, Permatod | ⬜ |

## Phase 11 · Team-Werkzeuge und Betrieb

| Nr. | Punkt | Status |
| --- | --- | --- |
| 11.1 | Team-Menü (F9) | ⬜ |
| 11.2 | Tickets und Spieler-Akte | ⬜ |
| 11.3 | Anti-Cheat | ⬜ |
| 11.4 | Backups, Monitoring, Neustarts, Testserver | ⬜ |
| 11.5 | Wochenberichte (Geldmenge, Aktivität) | ⬜ |

## Phase 12 · Beta und Start

| Nr. | Punkt | Status |
| --- | --- | --- |
| 12.1 | Geschlossene Beta (10 Slots, 2 Wochen) | ⬜ |
| 12.2 | Balancing über Config | ⬜ |
| 12.3 | Regelwerk und Einstiegstexte | ⬜ |
| 12.4 | Start | ⬜ |
