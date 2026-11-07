# Entscheidungsprotokoll

Jede Entscheidung mit Datum, Entscheider und Begründung. Neueste zuerst. Was hier steht, gilt; was nicht hier steht, ist offen.

| Datum | Thema | Entscheidung | Begründung |
| --- | --- | --- | --- |
| 2026-11-07 | Punkt 0.15 Design | Design V5 „Nachtviolett“ (Violett-Akzent, kühles Glas, Schwarzgeld Mint) ersetzt die Gelb-Orange-Farbwelt; Aufbau und Bedienung von V4 bleiben. Neue Oberflächen werden erst gebaut, wenn das System dran ist | Entscheidung des Betreibers; Phase 0 damit komplett |
| 2026-11-07 | Punkt 0.14 Voice | SaltyChat (TeamSpeak 3) als einzige Fremd-Resource im Voice-Bereich; TeamSpeak-Server mit Non-Profit-Lizenz auf dem VPS (Punkt 1.10); Funk, Handy, Sprechweiten und HUD-Anzeige werden selbst auf SaltyChat aufgesetzt (Phase 6/7) | Entscheidung des Betreibers |
| 2026-11-07 | Punkt 0.13 Betrieb | Live `/opt/tacov2` (main, Port 30121), Testserver `/opt/tacov2-test` (develop, DB `tacov2_test`, Port 30122) auf demselben VPS; Neustart alle 6 Stunden (00/06/12/18 Uhr) mit Ansagen 15/5/1 min; DB-Backup täglich 05:30 + vor jedem Deploy, 14 Tage; Monitoring als Embed im Discord-Kanal „Server Status“ mit allen öffentlichen Infos (online/offline, Spieler/Slots, nächster Neustart, Laufzeit, Version); Slot-Stufe neu entscheiden, wenn an 3 von 7 Tagen voll | Entscheidung des Betreibers |
| 2026-11-07 | Punkt 0.12 Anti-Cheat | Eigener Abgleich im Kern (Geld/Items gegen Journal, Geschwindigkeit/Teleport, Entity-Spam, Waffen ohne Item, Leben/Weste, verbotene Events, Zweitkonten); Meldung ans Team, automatische Sperre nur bei eindeutigen Fällen; kommerzielles Anti-Cheat erst ab mehr als 32 Slots prüfen | Entscheidung des Betreibers |
| 2026-11-07 | Punkt 0.11 Team-Rollen | Zehn Discord-Rollen (Projektleitung, Stv. Projektleitung, Manager, Superadministrator, Administrator, Entwickler, Moderator, Supporter, Guide, Gamedesigner) werden vom Bot nach `players.role` gespiegelt; Rechte je Stufe in `config/permissions.lua`; Team-Rechte nur im Admin-Dienst (Aduty, F9/`/aduty`) | Entscheidung des Betreibers („wie der bekannte Aduty“) |
| 2026-11-07 | Punkte 0.2–0.10 | Konzeptkapitel 1–5 sowie Items- und Orte-Tabellen beim Neudurchgang unverändert bestätigt | Betreiber: „passt“ |
| 2026-11-07 | Spielstil | TacoV ist ein Softcore/Midcore-Server mit Bodyshot-Schadensmodell (keine Kopfschuss-Sofortkills) | Entscheidung des Betreibers |
| 2026-11-07 | Vorgehen | Entwicklung Punkt für Punkt nach `docs/punkte.md`, von vorn; eigene Phase für Entwickler- und Admin-Werkzeuge (Creator-Systeme) direkt nach den Fahrzeugen | Entscheidung des Betreibers |
| 2026-11-07 | Punkt 0.1 | Name TacoV, 10 Slots (Stufen 32/64/128), Deutsch, Los Santos Gegenwart, 18+ bestätigt | Betreiber: „wir starten sofort“ |
| 2026-11-07 | Fahrzeuge | Erste Kaufliste mit 52 Grundspiel-Modellen in den Klassen D/C/B/A/S/Motorrad/Transporter/LKW mit Preisen aus Konzept 3; Garagen sind alle öffentlichen Parkplätze der Karte (16 PKW, 5 LKW) plus Verwahrhof Mission Row; Kofferraum je Klasse: Einstieg 20 kg, Alltag 40, Gehoben 60, Sport/Super 25, Motorrad 10, Transporter 120, LKW 300 | Entscheidung des Betreibers |
| 2026-11-07 | Fahrzeuge · Übergang | Bis DMV und Fahrschule stehen: Zulassung (150 $) beim Kauf fällig, keine Führerschein-Prüfung (`requireLicense = false`); nach einem Server-Neustart stehen unterwegs gewesene Fahrzeuge im Verwahrhof, Auslösung kostenlos wenn in den letzten 24 h gefahren | Spielbar ohne offene Module, nichts geht verloren |
| 2026-11-07 | Modulschnitt | Module bleiben Dateien im Kern (`tacov_core`) statt eigener Resources: FiveM-Exports dürfen nicht warten (DB, Journal), eine Modul-Resource bräuchte doppelte Hüllen | Weniger Fehlerquellen; der Ordnerschnitt in `docs/framework.md` gilt erst, wenn eine Bridge ohne Warten existiert |
| 2026-11-07 | Design V4 | Alle Oberflächen im Spiel auf das V4-Design umgestellt (Vorbild: GLRP-Referenzen, Akzent Gelb-Orange aus dem Logo, Schrift Barlow + Kaushan Script): Panels mit Kopfzeile, Listenmenüs per Tastatur (↑ ↓ Enter ⌫ Esc), E-Ring für Orte/Objekte, X-Rad nur Spieler/Fahrzeuge; Interaktions-UIs (X-Rad, Menü) leicht transparent, Vollbild-UIs (Inventar, Bank, Laden) deckend; HUD ohne Karten-Rahmen, Infozeilen rechts neben der Vanilla-Minimap, Funkliste statt Spielerliste, Fitness unten statt rechts, Tankstellenkarte über dem Tacho | Entscheidung des Betreibers nach Abnahme der V4-Tafeln |
| 2026-11-06 | Bedienung | X-Rad nur für Interaktionen mit Spielern und Fahrzeugen; alles andere (Orte, Objekte) per E-Aufforderung | Entscheidung des Betreibers |
| 2026-11-06 | Inventar | Startitems Ausweis und Stadtplan bei der Anlage (kein Handy); Raster ohne Platzlimit, Gewicht ist die einzige Grenze; Bargeld hat kein Gewicht (Schwarzgeld 0,1 kg je 1.000 $ bleibt) | Entscheidung des Betreibers |
| 2026-11-06 | Resource-Namen | Ordner heißen `tacov_<name>` (FiveM nimmt den Ordnernamen als Resource-Namen) | Dependency und Exports brauchen den echten Namen |
| 2026-11-06 | Framework | Komplett eigenes Framework ohne Fremd-Resources: oxmysql ersetzt durch eigene Resource `tacov_db` (nur der mysql2-Treiber ist Fremdcode); Aufbau in `docs/framework.md` | Entscheidung des Betreibers |
| 2026-11-06 | UI-Technik | React 19 + TypeScript mit esbuild; Build eingecheckt in `core/ui/`; eine NUI-Seite für alle Ansichten | Einfacher Build, Server nach `git pull` sofort spielbar |
| 2026-11-05 | VPS | Neuer Server liegt unter `/opt/tacov2` mit Nutzer, Datenbank und Diensten `tacov2`, Port 30121 | Getrennt vom bestehenden `tacov`-Ordner auf dem VPS |
| 2026-11-05 | Discord-Bot | Eigener Bot in Node.js (discord.js), teilt sich die Datenbank mit dem Spielserver; Whitelist per Reaktion, Log-Spiegel | Bester Discord-Support, läuft unabhängig vom Spielserver |
| 2026-11-05 | Datenbankzugriff | oxmysql (MIT) als einzige Fremd-Resource; alle Module gehen über `TacoV.DB` | Stabil, frei, kein Framework-Zwang |
| 2026-11-05 | Phase 1 | Design abgenommen (37 Boards im Canvas „TacoV Spiel-UI“, Befehlszeile oben links); Phase 2 Kern + Bot begonnen | Freigabe des Betreibers |
| 2026-11-05 | Design | Die 27 Grundoberflächen des V3-Designs (Gelb-Orange) aus dem Canvas „TacoV Spiel-UI“ sind die Design-Basis; Anpassungen an Konzept V1 folgen | docs/design/README.md |
| 2026-11-05 | Konzept 5 | Alltag und Handy abgenommen: Inventar F2 (30 kg, Rucksack 45 kg, kein Schnellzugriff), Hunger/Durst 3 h, Fitness statt Stress, Promille, 10 Handy-Apps, Funkgerät schaltet Funk-App frei (Fraktionsfrequenzen 1–10), Animationen F3, Hände hoch H, Befehlszeile T, keine Namen über dem Kopf, Kleiderläden an allen Grundspiel-Standorten, Angeln/Muschelstrand/Gym zum Start | docs/konzept/05-alltag-handy.md |
| 2026-11-05 | Datenbank | MariaDB bleibt die Datenbank; phpMyAdmin wird als Weboberfläche dazu installiert (Webzugang) | phpMyAdmin ist eine Oberfläche für MariaDB/MySQL, kein Ersatz |
| 2026-11-05 | Konzept 4 | Verbrechen und Justiz abgenommen: 5 Drogenketten (Meth, Frösche im Camper), keine Seriennummern, Schrotflinte/Schlagstock/Taser nur Staat, Waffenbau 3 Langwaffen je Tag, eine unsichtbare Weste (farmbar), Raub: Ladenraub, ATM ab 2 Polizisten, Fleeca Paleto, Juwelier, Staatsbank ab 10 (Dev 2), Beute über zwei Hehler, Koma nach 15 min mit Verlust alles Getragenen, Permatod nur per Discord-Antrag, Ausbruch möglich; Fahrzeugdiebstahl und Einbruch auf der Ideenliste | docs/konzept/04-verbrechen-justiz.md |
| 2026-11-05 | Konzept 3 | Wirtschaft abgenommen: 6 Jobs, eine Firma (Burger Shot), Schwarzgeld ab Start mit je Fraktion freischaltbarer Wäsche, Kaufzeiten 10/40/80/200 h, Einkommensteuer 8 %, alle Fahrzeugklassen im NPC-Autohaus plus eigene Kaufhäuser für LKW, Boote, Flugzeuge | docs/konzept/03-wirtschaft.md |
| 2026-11-05 | Konzept 2 | Fraktionen abgenommen: Caps LSPD 20, LSMD offen, DMV 10, Regierung nur Team, DOJ 15, Gang 15; Austrittssperre 5 Tage (Gang zu Staat 3); Gangwar 19–23 Uhr, Krieg max. 7 Tage; F6 | docs/konzept/02-fraktionen.md |
| 2026-11-05 | Konzept 1 | Leitbild und Einstieg abgenommen: Startgeld 5.000 $, Sozialwohnung 14 Tage, Einreise nur mit Teammitglied, erneuter Versuch nach 24 h, keine Kontoalter-Prüfung, Level 3/8/15 | docs/konzept/01-leitbild-einstieg.md |
| 2026-11-05 | Kriminelle Fraktionen zum Start | Eine Streetgang | 10 Slots tragen nicht mehr |
| 2026-11-05 | Name | TacoV ist der endgültige Name | Entscheidung des Betreibers |
| 2026-11-05 | Staatsfraktionen zum Start | LSPD, LSMD, DMV, Regierung, DOJ | Kleiner Kern, der mit 10 Slots bespielbar ist; weitere Fraktionen in Seasons |
| 2026-11-05 | Slots zum Start | 10, Erhöhung in Stufen je nach Spielerzahl | Kleiner Start, kontrolliertes Wachstum |
| 2026-11-05 | Whitelist | Beitritt per Reaktion auf eine Discord-Nachricht; kein Regeltest, kein Formular; Prüfung erfolgt IC bei der Einreise | Niedrige Hürde, Eignung wird im Spiel geprüft |
| 2026-11-05 | Vorbild | Nur GVMP als Struktur-Vorbild; keine Ideen, Werte oder Namen aus früheren Konzepten oder Projekten | Komplett neues Projekt |
| 2026-11-05 | Entwicklungsweg | Entwicklung im Repository, Deploy auf den VPS per `git pull` | VPS bleibt nie halbfertig |
| 2026-11-05 | Technik | Eigenes Framework in Lua, React-UI, MariaDB, TeamSpeak-Voice; kein ESX, kein QBCore | Volle Kontrolle, kein Fremdcode |

## Offen (Phase 0)

| Thema | Optionen | Frist |
| --- | --- | --- |
| Team-Rollen | Supporter, Admin, Management, weitere | 2026-11-22 |
| Anti-Cheat | Nur eigener Abgleich oder plus kommerzielles Produkt | 2026-11-22 |
| Hoster und VPS | Standort, DDoS-Schutz, Testserver | 2026-11-22 |
| Voice | TeamSpeak-Plugin und Lizenz | 2026-11-22 |
