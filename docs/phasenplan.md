# TacoV · Phasenplan

Stand: 07.11.2026. Dieser Plan ist die verbindliche Reihenfolge für den Bau des Servers. Jede Phase hat ein Ziel, Inhalte mit Verweis auf das Konzept (`docs/konzept/`), die nötigen Oberflächen, die Datenbanktabellen, die offenen Entscheidungen des Betreibers und eine Abnahme (wann ist die Phase fertig). Der Plan wird fortgeschrieben; Änderungen stehen in `docs/entscheidungen.md`.

Die Phasen sind in `docs/punkte.md` in einzelne Punkte (ein Punkt = ein System) zerlegt; dort steht der Abnahme-Status je Punkt.

## Überblick

| Phase | Thema | Stand |
| --- | --- | --- |
| 0 | Konzept und Entscheidungen | ✅ fertig |
| 1 | Infrastruktur: Repo, CI, VPS, Datenbank, Discord-Bot, Whitelist | ✅ fertig |
| 2 | Kern: eigenes Framework (`tacov_db`, `tacov_core`) | ✅ fertig |
| 3 | Alltag I: Oberfläche V4, HUD, Inventar, Bedürfnisse, Bank, Läden, Orte | ✅ fertig |
| 4 | Fahrzeuge | 🔶 Teil 1 fertig, Teil 2 offen |
| 5 | Entwickler- und Admin-Werkzeuge: Creator-Systeme (Türen, Aufzüge, Orte, Peds, Objekte, Zonen), Team-Menü | ⬜ |
| 6 | Charakter und Einstieg: Aussehen, Kleidung, Einreise, Animationen, Voice | ⬜ |
| 7 | Handy und Funk | ⬜ |
| 8 | Jobs, Lohn, Steuern, Staatshaushalt | ⬜ |
| 9 | Fraktionen: Modul, Dienst, LSPD/LSMD/DMV/Regierung/DOJ, Gang | ⬜ |
| 10 | Immobilien und Firmen | ⬜ |
| 11 | Verbrechen und Justiz | ⬜ |
| 12 | Team-Werkzeuge und Betrieb (Vervollständigung) | ⬜ |
| 13 | Beta und Start | ⬜ |

**Reihenfolge, kurz begründet:** Erst alles, was ein Zivilist am ersten Abend braucht (Phasen 3–4 und 6–8: laufen, essen, Geld, Auto, Aussehen, Handy, Job). Dazwischen die Creator- und Admin-Werkzeuge (5), weil Türen, Aufzüge, Orte und Peds für alle folgenden Systeme gebraucht werden und das Team damit Inhalte ohne Code setzt. Dann die Fraktionen (9), weil Polizei und Medic ohne Alltag nichts zu tun hätten. Immobilien und Firmen (10) brauchen Einkommen aus 8. Verbrechen (11) braucht Polizei und Justiz aus 9. Betriebswerkzeuge (12) wachsen über alle Phasen mit und werden vor der Beta vollständig gemacht.

**Spielstil (Konzept 1.2):** Softcore/Midcore mit Bodyshot-Schadensmodell – jedes System wird daran gemessen: Konsequenzen spürbar, aber nicht existenzbedrohend; keine Kopfschuss-Sofortkills.

**Arbeitsweise je Phase (gilt immer):**
1. Oberflächen zuerst als Tafel im Canvas „TacoV Spiel-UI“ (V4-Stil) – Betreiber nimmt ab oder korrigiert.
2. Umsetzung in Blöcken: Config aus dem Konzept → Datenbank → Server-Logik → Client → UI → Doku.
3. Betreiber testet auf dem VPS (`deploy.sh`), meldet Fehler; ich behebe, bevor der nächste Block kommt.
4. Phase ist fertig, wenn die Abnahme-Punkte durchgespielt sind und `docs/module/*.md` den Stand beschreibt.

---

## Phase 0 – Konzept und Entscheidungen ✅

Fünf Konzeptkapitel (Leitbild/Einstieg, Fraktionen, Wirtschaft, Verbrechen/Justiz, Alltag/Handy), Items- und Orte-Tabellen, Entscheidungslog. Abgenommen am 05.11.2026.

Noch offen aus Phase 0 (Frist 22.11.2026): Team-Rollen im Detail, Anti-Cheat (eigener Abgleich oder zusätzlich kommerziell), Hoster-Details/Testserver, TeamSpeak-Plugin und Lizenz.

## Phase 1 – Infrastruktur ✅

GitHub-Repo `tacov-team/tacov2.0`, CI (luacheck, Struktur- und Geheimnis-Prüfung, Node-Syntax), VPS `/opt/tacov2` (Benutzer, MariaDB, phpMyAdmin, FXServer in `screen`, Deploy per `git reset --hard origin/main`), Discord-Bot (Whitelist per Reaktion, Log-Spiegel in 11 Kanäle). Geheimnisse nur in `server.cfg`/`.env` auf dem VPS.

## Phase 2 – Kern ✅

`tacov_db` (eigener Datenbank-Treiber im FXServer-Node), `tacov_core`: Spieler über Discord-ID, 2 Charakterplätze, Journal als einziger Geldweg, Konten, Rechte/Rollen, Logs, Migrationen, Befehlszeile, Orte mit `/ort setzen`, Spielzeit/Level, Autosave.

## Phase 3 – Alltag I ✅

Oberfläche V4 (Barlow/Kaushan Script, Gelb-Orange), HUD mit Fahrzeug-Tacho, Hinweise, Befehlszeile (T), Charakterauswahl, Inventar (F2) mit Ablagen, Bedürfnisse Hunger/Durst, Hände hoch (H), Bank und Geldautomat, Läden (24/7, LTD, Rob's, Baumarkt), 79 Item-Icons, Listenmenü, E-Aufforderungen, X-Rad für Spieler/Fahrzeuge.

Offen in dieser Phase: Schriftdateien in `ui/public/fonts/` ablegen (Betreiber).

## Phase 4 – Fahrzeuge 🔶

**Teil 1 (fertig):** Kaufliste 52 Modelle in 8 Klassen, Autohaus (PDM) mit Vorschau und Ausfahrt draußen, LKW-Kaufhaus, 21 Garagen (alle Parkplätze der Karte), Verwahrhof, Schlüssel (geben, Schloss), Kofferraum als Inventar, 27 Tankstellen mit Verbrauch, Herzschlag/Kilometer, Tankstellenkarte im HUD, Fahrzeugmenü (F6 → Fahrzeug, X-Rad).

**Teil 2 (nächster Block):**
- DMV: Zulassung (150 $) und Halterwechsel (100 $, beide Unterschriften) statt automatischer Zulassung beim Kauf – Konzept 3.4
- Fahrschule: Theorie (Fragen aus Config) und Praxisfahrt; Führerscheine A, B, C; danach `requireLicense = true`; Punkte und Entzug ab 8 – Konzept 3.4, Tafel „V4 · Fahrschule“
- NPC-Werkstatt: Reparatur, Notreparatur auf 30 %, Upgrades (Bremsen, Motor, Getriebe, Turbo, Fahrwerk) als Untermenüs, Zubehör (Farbe, Felgen, Fenster) – Tafeln nach den GLRP-Referenzen
- Blitzer: 6 feste Stellen, Bußgeld vom Konto, Punkte ans DMV
- Kfz-Steuer 1 %/Jahr wöchentlich anteilig; Garagen an Immobilien kommen in Phase 9
- Verschleiß: Motor-/Karosseriezustand bleibt über Garage erhalten (Grundlage vorhanden)
- Boote und Flugzeuge: Kaufhäuser und Garagen sind vorbereitet (Kategorien sea/air), Freischaltung ist eine eigene Entscheidung

Tabellen: `vehicles`, `vehicle_keys` (vorhanden), neu `licenses`, `speedcam_fines`. Entscheidungen: Preise Fahrschule, Upgrade-Preise (Vorschlag 5/10/20 % vom Kaufpreis), Blitzer-Stellen.

Abnahme: Kaufen → Zulassung → Fahrschule → tanken → Werkstatt → einparken → Verwahrhof auslösen; ein zweiter Spieler bekommt einen Schlüssel und fährt.

## Phase 5 – Entwickler- und Admin-Werkzeuge ⬜

Creator-Systeme, mit denen das Team Inhalte ohne Code setzt, plus Admin-Grundgerüst. Alles speichert in der Datenbank, hat Rechte je Rolle und wird geloggt.

- Admin-Grundgerüst: Admin-Modus, Unsichtbar, Noclip, Teleport; Team-Menü (F9) mit Spielerliste, Akte, Geben, Heilen, Kicken, Sperren
- Orte-Creator (ersetzt `/ort setzen`), Door Creator (Türen/Tore mit Zugang je Fraktion/Rang/Schlüssel), Elevator Creator (Etagen), Teleport-Creator (Interiors), Ped-Creator (Ansprechpartner), Objekt-Placer, Zonen-Creator (Gebiete, Sicherheitszonen)
- Fahrzeug-Spawner/-Editor, Item- und Geld-Werkzeuge mit Vier-Augen-Prinzip, Welt-Steuerung (Wetter, Zeit, Ansagen), Config im Spiel
- Entwickler-Werkzeuge: Koordinaten kopieren, Entity-Info, Debug-Zonen, Hot-Reload der Config
- Spieler-Akte und Tickets im Spiel; Anti-Cheat-Grundlage

Tafeln: Team-Menü, Creator-Leiste (V4 neu). Tabellen: `doors`, `elevators`, `portals`, `peds`, `props`, `zones`, `tickets`, `admin_log`. Entscheidungen: Team-Rollen (0.11), welche Rolle welche Creator bedienen darf.

Abnahme: Ein Teammitglied setzt im Spiel eine Tür mit LSPD-Zugang, einen Aufzug mit drei Etagen und einen Ansprechpartner – ohne Neustart; ein Spieler ohne Rechte kommt nicht durch die Tür.

## Phase 6 – Charakter und Einstieg ⬜

- Charaktereditor bei der Anlage (Gesicht, Eltern-Mix, Haare, Farben), Speicherung in `appearance` – Konzept 5.4
- Kleiderläden (15 Orte), Friseur (7), Tattoo (6), Chirurg im Krankenhaus; 10 Outfits je Charakter; Maske verbirgt den Ausweis
- Ladebildschirm und Einreise: Ankunft am Flughafen, Einreise nur mit Teammitglied, Neulingspfad, Sozialwohnung 14 Tage, erneuter Versuch nach 24 h – Konzept 1.4
- Animationsmenü (F3): 40 Animationen, Favoriten – Konzept 5.5
- Voice: TeamSpeak-Plugin, Sprechweiten 3/10/25 m mit HUD-Anzeige – braucht Entscheidung Lizenz (Phase 0)
- Verletzungen leicht/mittel/schwer mit Erste-Hilfe-Kit (Grundlage für LSMD in Phase 8)

Tafeln: Charaktereditor, Kleidungsladen, Ladebildschirm, Animationen (alle als V4 neu zeichnen). Tabellen: `outfits`, `character_licenses` (Einreise-Status). Entscheidungen: Voice-Lösung; Preise Kleidung/Friseur/Tattoo (Vorschlag aus Konzept-Spannen).

Abnahme: Neuer Spieler erstellt Charakter mit Aussehen, reist mit Teammitglied ein, kauft Kleidung, speichert ein Outfit, spricht in drei Reichweiten.

## Phase 7 – Handy und Funk ⬜

- Handy als Item (F1 nur mit Handy), Nummer je Charakter – Konzept 5.3
- Apps in dieser Reihenfolge: Kontakte, Nachrichten (SMS, Standort, Gruppen bis 8), Bank, Fahrzeuge (Standort, Garage, Tank, Schlüssel teilen), Einstellungen; danach Notruf, Fraktion, Firma, Kamera, Feed mit den jeweiligen Phasen
- Anrufe über TeamSpeak-Privatkanal (Voice aus Phase 5)
- Funkgerät (250 $) schaltet Funk-App frei, Frequenzen 1–999, 1–10 Fraktionen; Funkliste im HUD wird live
- Tablet (MDT, Lagerverwaltung) erst in Phase 8

Tafel: „V4 · Handy“ (vorhanden, nach Abnahme der Realismus-Korrektur). Tabellen: `phone_contacts`, `phone_messages`, `phone_calls`, `radio_channels`. Entscheidungen: Handypreis, Sperre bei Beschlagnahme.

Abnahme: Zwei Spieler tauschen Nummern, schreiben, telefonieren, funken auf einer Frequenz; Funkliste im HUD zeigt, wer spricht.

## Phase 8 – Jobs, Lohn, Steuern, Staatshaushalt ⬜

- Sechs Jobs: Müllabfuhr, Lieferfahrer, Busfahrer, Taxi, Holzfäller, Bergbau – Konzept 3.2 (Lohn, Stundenlimit, Führerschein-Voraussetzung aus Phase 4)
- Jobcenter, Job-Ansprechpartner an den Orten, Firmenfahrzeuge vom Hof
- Payday je Spielstunde, Einkommensteuer 8 %, Umsatzsteuer (vorhanden), Kfz-Steuer (Phase 4)
- Staatshaushalt: Einnahmen/Ausgaben, Fraktionsgehälter, Geldmengen-Report wöchentlich ans Team
- Kaufzeiten-Simulation in der CI (10/40/80/200 h) – Konzept 3.9
- Schwarzgeld: entsteht ab Phase 10; Wäsche je Fraktion freischaltbar

Tafeln: Jobs (V3 vorhanden, V4 neu). Tabellen: `jobs_sessions`, `payday_log`. Entscheidungen: Lohnwerte final (Konzept-Spannen), Startjobs ohne Führerschein.

Abnahme: Ein Spieler verdient in einer Stunde mit zwei Jobs; Steuern landen im Staatshaushalt; Simulation läuft grün.

## Phase 9 – Fraktionen ⬜

- Fraktionsmodul: Mitglieder, Ränge, Rechte je Rang, Kasse, Lager, Fahrzeuge (Fraktionsfahrzeuge), Protokoll; Fraktionsmenü F6 vollständig – Konzept 2.1
- Dienst an/aus mit Dienstkleidung aus dem Fraktions-Katalog, Caps (LSPD 20, DMV 10, DOJ 15, Gang 15), Austrittssperre 5 Tage
- LSPD: MDT (Akten, Fahndung, Fahrzeugabfrage), Dispatch mit Notrufen, Beschlagnahme, Verhaftung (Grundlage für Phase 10), Waffenschein-Prüfung
- LSMD: Verletzungssystem fertig (stabilisieren, Krankenhaus 5 min), Koma-Ablauf, Rechnungen
- DMV: Führerscheinprüfung und Zulassung übernehmen (aus Phase 4), Punkte
- Regierung (nur Team) und DOJ: Rathaus mit Bürgerbüro und Lizenzamt, Gericht (Kaution, Verfahren) – Oberflächen
- Streetgang: Ganghaus (Grove Street oder Rancho), Gebiete, Gangwar 19–23 Uhr, Krieg max. 7 Tage – Konzept 2.4/2.5

Tafeln: Fraktionsmenü, MDT, Dispatch, Rathaus, Gericht (V3 vorhanden, V4 neu). Tabellen: `factions`, `faction_members`, `faction_ranks`, `faction_log`, `mdt_*`, `territories`. Entscheidungen: Rangnamen je Fraktion, Ganghaus-Standort, Gehälter.

Abnahme: LSPD-Spieler geht in Dienst, nimmt Notruf an, kontrolliert ein Fahrzeug über das MDT; LSMD versorgt einen Verletzten; Gang hält ein Gebiet.

## Phase 10 – Immobilien und Firmen ⬜

- Immobilien: Sozialwohnung (14 Tage gratis), Wohnung, Haus, Villa, Lager; Kauf oder Miete, Schlüssel bis 5, Lager und Garage je Typ, Weiterverkauf über Standesamt 5 %, Mietrückstand 2/4 Wochen – Konzept 3.5
- Möbelhaus Hawick (Einrichtung Grundumfang)
- Firma: Burger Shot (Bewerbung ab Level 9, Kaution 15.000 $), Mitarbeiter, Kasse, Großhandel, Zubereitung, Lieferungen per Handy – Konzept 3.6; weitere Firmentypen bleiben gesperrt

Tafeln: Immobilien/Makler, Firma (neu). Tabellen: `properties`, `property_keys`, `businesses`, `business_employees`, `business_orders`. Entscheidungen: Anzahl und Lage der Immobilien zum Start, Burger-Shot-Preise.

Abnahme: Spieler mietet Wohnung, lagert Items, gibt Schlüssel; Burger Shot verkauft an einen Kunden.

## Phase 11 – Verbrechen und Justiz ⬜

- Drogen: Anbau/Herstellung (Labor Camper/Station), Verkauf an NPC und Spieler, Wirkung – Konzept 4.1
- Waffen: Waffenschein, legaler Kauf, Schwarzmarkt, Munition als Item, Hehler – Konzept 4.2
- Raub: Läden, Juwelier (Vitrinen, Safe), Bank-Überfall mit Leiste, Spieler ausrauben – Konzept 4.3
- Strafkatalog, Haft (Gefängnis mit Terminal), Kaution, Geldstrafen, Punkte – Konzept 4.5/4.6
- Koma, Tod, Permatod-Regeln – Konzept 4.7
- Schwarzgeld und Wäsche; Blitzer-Bußgelder (Phase 4) fließen in Akten

Tafeln: Gefängnis, Hehler, Schwarzmarkt, Labor, Überfall-Leiste (V3 vorhanden, V4 neu). Tabellen: `crime_records`, `jail_sentences`, `drug_plots`, `heists`. Entscheidungen: Freischaltung je Delikt (jedes einzeln), Strafhöhen final.

Abnahme: Kompletter Bogen Raub → Verfolgung → Verhaftung → Gericht → Haft → Entlassung mit zwei Teams durchgespielt.

## Phase 12 – Team-Werkzeuge und Betrieb ⬜

- Team-Menü (F9): Spielerliste, Teleport, Unsichtbar, Items/Geld geben mit Log, Sperren, Tickets, Fahrzeuge spawnen – Rechte je Rolle
- Support-Tickets im Spiel und Discord, Spieler-Akte (Logs je Charakter)
- Anti-Cheat: eigener Abgleich (Geld, Items, Geschwindigkeit, Entity-Spam), Entscheidung aus Phase 0 zu Zusatzprodukt
- Betrieb: Backups der Datenbank (täglich, 14 Tage), Monitoring (Server läuft, DB erreichbar), Neustart-Fenster, Testserver-Instanz, Changelog für Spieler
- Geldmengen- und Aktivitäts-Report wöchentlich an das Team

Tafeln: Team-Menü (V3 vorhanden, V4 neu). Entscheidungen: Team-Rollen final (Phase 0), Neustart-Zeiten.

Abnahme: Team bearbeitet ein Ticket, sperrt und entsperrt einen Test-Account, Backup wird eingespielt.

## Phase 13 – Beta und Start ⬜

- Geschlossene Beta mit 10 Slots (Whitelist), zwei Wochen; Testprotokolle je Modul in `docs/module/*.md`
- Balancing nach Daten: Kaufzeiten, Löhne, Preise – Anpassungen nur über Config
- Regelwerk und Einstiegstexte final (Discord, Ladebildschirm)
- Start: Slots in Stufen erhöhen (Entscheidung Phase 0), Seasons für weitere Fraktionen planen

Abnahme: Zwei Wochen Beta ohne offene Fehler der Stufe „blockiert Spielfluss“; Team-Freigabe.

---

## Was ich bei jeder Phase vom Betreiber brauche

1. Antworten auf die Entscheidungen der Phase (kurz, „1 ja, 2 ja, 3 andere Werte“ reicht).
2. Abnahme der Tafeln im Canvas, bevor gebaut wird.
3. Testen auf dem VPS nach jedem Block und Rückmeldung, was hakt – mit Screenshot, wenn es um Position oder Optik geht.
4. Alles, was ich nicht selbst herunterladen kann (Schriften, eigene Bilder, Fahrzeug-Mods), im Repo ablegen oder in den Chat laden.
