# Modul: Kern (`tacov_core`)

Phase 2. Grundlage für alle anderen Resources: Datenbank, Spieler, Charaktere, Konten mit Journal, Rechte, Logs, Befehle.

## Dateien
| Datei | Aufgabe |
| --- | --- |
| `config/core.lua` | Slots, Autosave, Charakterplätze, Whitelist-Texte, Einstieg, Level, Bedürfnisse, Inventar, Tasten, Voice |
| `config/economy.lua` | Bank, Steuern, Tanken, Staatshaushalt, Schwarzgeld, Jobs, Gehälter |
| `config/permissions.lua` | Rollen (player/supporter/admin/management) und Rechte |
| `shared/util.lua` | Geld runden, Zahlenbereich, Text bereinigen, Convar |
| `server/db.lua` | Hülle um die eigene Resource `tacov_db`; andere Module nutzen nur `TacoV.DB` |
| `server/migrations.lua` + `sql/NNN_*.sql` | Schema; läuft beim Start, merkt sich Version in `migrations` |
| `server/log.lua` | `TacoV.Log.write(kategorie, text, {characterId, discordId, data})` → Tabelle `logs`, Bot spiegelt in Discord |
| `server/journal.lua` | `TacoV.Journal.move(kind, from, to, amount, reason)` – die einzige Stelle für Geldbewegungen |
| `server/status.lua` | Status-Zeile alle 30 s (`server_status`), Neustart-Planer alle 6 h mit Ansagen 15/5/1 min (Spiel + `announcements`), Autosave und `quit`; `/neustart <Minuten>` (Manager) |
| `server/permissions.lua` | `TacoV.Permissions.has(source, recht)` |
| `server/players.lua` | Spielerkonto je Discord-ID, Online-Liste, Teamliste |
| `server/characters.lua` | Liste, Anlage (Namensregeln, Blockliste, 2. Platz ab Level 15), Laden, Speichern, Spielzeit ohne AFK |
| `server/accounts.lua` | `pay`, `receive`, `tax` für andere Module |
| `server/connect.lua` | `playerConnecting`: Discord-ID Pflicht → Sperre → Whitelist → Slots → Doppelverbindung |
| `server/status.lua` | Status-Zeile alle 30 s (`server_status`), Neustart-Planer alle 6 h mit Ansagen 15/5/1 min (Spiel + `announcements`), Autosave und `quit`; `/neustart <Minuten>` (Manager) |
| `server/permissions.lua` | Rechteprüfung gegen `config/permissions.lua`; Admin-Dienst (Aduty) je Spieler, Rolle wird beim Dienstbeginn frisch aus der DB gelesen |
| `config/shops.lua` | Ladentypen Supermarkt, Baumarkt, Waffenladen (lizenzpflichtige Artikel gesperrt bis Waffenschein) |
| `server/commands.lua` | `/support`, `/aduty`, `/ort setzen|liste`, `/geld` (Team), `/rolle`, `/sperre`, `/kick`; einmaliger Startbonus über Convar `tacov_grant_next` |
| `server/main.lua` | Startfolge, Autosave, Speichern beim Stop |
| `client/main.lua` | Anmeldung, Spawn nach Charakterwahl, Herzschlag (Position, Aktivität) |
| `client/ui.lua` | NUI-Brücke (`TacoV.UI.open/close/send/openConsole`), Befehlszeile führt Befehle aus |
| `client/hud.lua` | HUD-Daten: Leben/Weste/Straße vom Client, Bedürfnisse vom Server, Minimap-Lage, Fahrzeugwerte (km/h, Tank, Motor, Schloss; `TacoV.Hud.tankCapacity` ersetzt das Fahrzeugmodul); Hungerschaden |
| `client/menu.lua` | Listenmenüs mit Untermenü-Stapel: `TacoV.Menu.open(def, onSelect)`, `update`, `back`, `close` |
| `client/keys.lua` | Tastenbelegung aus `config/core.lua` (T, F1, F2, F3, F6, F9, X, H); F6 öffnet das Aktionsmenü mit Zivilistenaktionen |
| `config/commands.lua` | Befehlsliste für die Befehlszeile |
| `server/needs.lua` | Hunger/Durst sinken je Minute, Promille baut ab; `needsAdd` für Essen/Trinken |
| `config/items.lua` | Alle Items (Gewicht, Stapel, Kategorie, Wirkung), Startausrüstung |
| `server/inventory.lua` | Inventar: Raster mit Gewicht als Grenze, Stapeln, Verschieben, Geben, Ablagen am Boden (15 min), Benutzen, Bargeld/Schwarzgeld als Items mit Journal |
| `client/inventory.lua` | F2, Zielspieler für „Geben“, Ablagen, Ess-/Trinkanimation |
| `config/locations.lua` / `server/locations.lua` / `client/locations.lua` | Orte (Banken …) aus Config, Überschreibung aus Tabelle `locations`, Blips, Nähe-Abfragen |
| `server/bank.lua` / `client/bank.lua` | Bank (Schalter) und Geldautomat: Einzahlen, Abheben (Automat max. 5.000 $), Überweisen (Name/Kontonummer, 50.000 $/Tag, 1 % ab 10.000 $), Kontoauszug |
| `config/shops.lua` / `server/shops.lua` / `client/shops.lua` | NPC-Läden (24/7, LTD, Rob's, Baumarkt): Sortiment und Preise, Kauf bar oder Karte, 5 % Umsatzsteuer an den Staat |
| `config/vehicles.lua` | Fahrzeugklassen (Level, Führerschein, Kofferraum, Tank), Kaufliste (52 Modelle), Garagen (16 PKW + 5 LKW), Verwahrhof, Kaufhäuser, 27 Tankstellen, Gebühren |
| `sql/003_vehicles.sql` | Tabellen `vehicles` (Halter, Zustand garage/out/impound, Tank, km, Zustand) und `vehicle_keys` |
| `server/vehicles.lua` | Besitz und Schlüssel, Garage (ein-/ausparken, 50 $/Tag ab 24 h), Verwahrhof (24 h unterwegs → verwahrt, 500 $; nach Neustart gratis wenn kürzlich gefahren), Kaufhaus (Preis + Zulassung 150 $, Level je Klasse), Tanken (Preis aus `economy.lua`, 5 % USt), Kofferraum (außen; offen = für alle, sonst Schlüssel) und Handschuhfach (innen, 5 kg) als Inventar-Behälter |
| `client/vehicles.lua` | Spawn auf Serveranweisung, Tank (Statebag `fuel` in Litern, Verbrauch nach Drehzahl, leer = Motor aus), Kilometer, Herzschlag 60 s, X-Rad (Auf-/Abschließen, Motor, Kofferraum, Schlüssel geben), E-Aufforderungen (Garage, Einparken, Kaufhaus, Tanken), Garage-Ansicht (Karten mit Suche/Filter), Kaufhaus-Menüs mit Vorschau und Kamera, Tankstellenkarte im HUD |
| `config/dmv.lua`, `sql/006_dmv.sql`, `server/dmv.lua`, `client/dmv.lua` | DMV Vespucci (NPC-Schalter bis zur Fraktion): Führerscheine A/B/C (`licenses`, Punkte, Entzug ab 8), Zulassung 150 $ (TMP → LS-Kennzeichen), Halterwechsel 100 $ mit Bestätigung des Käufers, Fahrschule (Theorie 8 Fragen/7 richtig als Menü, Praxisfahrt mit Kontrollpunkten, Tempolimit, Unfall, Zeit) |
| `config/workshop.lua`, `server/workshop.lua`, `client/workshop.lua` | NPC-Werkstatt (5 Orte): Reparatur (bis 10 % Kaufpreis nach Schaden, min. 150 $), Upgrades Motor/Bremsen/Getriebe/Fahrwerk in Stufen Straße/Sport/Rennen (5/10/20 %), Turbo 10 %, Lack 500 $, Fensterfarbe 300 $, Felgen 800 $; Ausstattung wird am Fahrzeug gespeichert (`props`) |
| `config/traffic.lua`, `server/traffic.lua`, `client/traffic.lua` | Blitzer (Orte `speedcam` mit `limit`; Client meldet, Server misst nach: Toleranz 5 km/h, Bußgeld 100/250/500/1000/2000 $ nach Überschreitung bis 10/20/30/50/mehr km/h, ab 21 km/h 1–3 Punkte, 60 s Sperre je Fahrzeug und Blitzer, Log `justice`) und Kfz-Steuer (1 % Kaufpreis je Jahr, wöchentlich anteilig vom Bankkonto des Halters, stündliche Prüfung; nicht gedeckt → `tax_due`, fällig beim Ausparken) |
| `client/interact.lua` | Interaktionsrad (X halten) nur für Spieler und Fahrzeuge: `TacoV.Interact.register` |
| `client/prompt.lua` | E-Aufforderungen für Orte und Objekte (Bank, Automat, Ablage …): `TacoV.Prompt.register` |
| `ui/` | Build der React-UI (Quelle in `/ui`) |

## Exports für andere Resources
`isReady`, `getPlayer(source)`, `getCharacter(source)`, `hasPermission(source, recht)`, `journalMove(...)`, `journalBalance(ownerType, ownerId)`, `accountPay/accountReceive/accountTax`, `needsAdd`, `inventoryAdd/inventoryRemove/inventoryCount(source, item, …)`, `cashAdd/cashRemove(source, amount, reason, 'cash'|'black')`; Client: `interactRegister(entry)`.

## Events
- Server → Client: `tacov:core:characters`, `tacov:core:characterLoaded`, `tacov:core:bank`, `tacov:core:notify`, `tacov:core:role`
- Client → Server: `tacov:core:clientReady`, `tacov:core:selectCharacter`, `tacov:core:createCharacter`, `tacov:core:heartbeat`
- Serverintern: `tacov:core:ready`, `tacov:core:locationChanged`

## Tabellen
001: `migrations`, `whitelist`, `players`, `bans`, `characters`, `accounts`, `journal`, `logs`, `name_blocklist`, `locations` · 002: `inventory_items`

## Abhängigkeit
`tacov_db` (eigene Resource, siehe `docs/module/db.md`); die Startreihenfolge regelt `dependency` im Manifest.

## Stand
- [x] Schema, DB-Hülle, Migrationen
- [x] Whitelist-Prüfung beim Verbinden
- [x] Spieler, Charaktere (1 Platz), Spielzeit, Autosave
- [x] Konten über Journal, Startgeld
- [x] Rechte, Grundbefehle
- [x] React-UI: HUD, Hinweise, Befehlszeile, Charakterauswahl (Phase 3)
- [x] Bedürfnisse Hunger/Durst, Hände hoch
- [x] Inventar (F2) mit Ablagen, Geben, Benutzen; Interaktionsrad (X); Startitems Ausweis + Stadtplan
- [x] Bank und Geldautomat, Orte mit Blips
- [x] Läden 24/7, LTD, Rob's, Baumarkt (22 Orte)
- [x] Design V4 in allen Oberflächen, Listenmenü (F6 Aktionsmenü), Fahrzeug-HUD-Daten
- [x] Fahrzeuge Teil 1: Kauf, Garagen, Verwahrhof, Schlüssel, Schloss, Tanken, Kofferraum, Verbrauch
- [x] Fahrzeuge Teil 2a: DMV (Zulassung, Halterwechsel) und Fahrschule (Führerscheine A/B/C)
- [x] Fahrzeuge Teil 2b: NPC-Werkstatt (Reparatur, Upgrades, Zubehör)
- [x] Fahrzeuge Teil 2c: Blitzer, Kfz-Steuer (Migration 007)
- [ ] Fahrzeuge Teil 2c: Blitzer, Kfz-Steuer
- [ ] Einreise-Ablauf mit Teammitglied (Phase 4, Modul Einstieg)
- [ ] Testprotokoll vom Testserver (sobald VPS/Datenbank stehen)
