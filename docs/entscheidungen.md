# Entscheidungsprotokoll

Jede Entscheidung mit Datum, Entscheider und Begründung. Neueste zuerst. Was hier steht, gilt; was nicht hier steht, ist offen.

| Datum | Thema | Entscheidung | Begründung |
| --- | --- | --- | --- |
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
