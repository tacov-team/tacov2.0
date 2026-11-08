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
| `server/admin.lua`, `client/admin.lua` | Admin-Grundgerüst: Unsichtbar (`support.invisible`), Noclip (`admin.noclip`; WASD, Q/E, Shift), Teleport zu Spieler/herholen/Wegpunkt/Koordinaten (`support.teleport`); Zustand als Statebag `admin_invisible`/`admin_noclip`, wird bei Dienstende zurückgesetzt; Team-Menü auf F9 im Dienst (Spieler laufen währenddessen weiter); Spieler-Akte und Aktionen (5.2): Heilen `support.heal`, Geld/Items `admin.give`, Fahrzeug `admin.vehicle.spawn` (`TacoV.Vehicles.grant`), Verwarnen `admin.warn` (Tabelle `warnings`), Kicken `admin.kick`, Sperren `admin.ban.temp` bis 7 Tage / `admin.ban`; Log `admin` |
| `client/creator.lua`, `server/creator.lua` | Creator-Grundlage: `TacoV.Creator.place(opts, cb)` (Kamera-Strahl, Leertaste Zeiger/fest, Pfeile/Bild↑↓ verschieben, Q/E drehen, Shift fein, Enter/Backspace), `TacoV.UI.ask(opts, cb)` Texteingabe (Ansicht `ask`); Orte-Creator (5.3): speichert in `locations` (`extra` JSON: noblip, spawn, preview, limit; `disabled` blendet Config-Orte aus), Recht `admin.locations`, Push an alle Clients |
| `client/doors.lua`, `server/doors.lua` | Door Creator (5.4): Tür-Teile (Modell+Position) im Door-System, Zustand zu/offen per Event synchron, Zugang `{faction,minRank}` oder `{item}` oder frei, Auto-Schließen in Sekunden; E-Aufforderung aufschließen/abschließen; Team mit `creator` bedient alle Türen; Tabelle `doors` |
| `server/access.lua` | Zugangsregeln für Türen/Aufzüge/Portale: `TacoV.Access.check(src, access)` (Fraktion+Mindestrang oder Schlüssel-Item, sonst frei; `creator` immer), `clean`, `text` |
| `client/teleports.lua`, `server/teleports.lua` | Aufzüge (5.5: Etagenliste, E → Etagenwahl → Blende) und Portale (5.6: Eingang/Ausgang, Einbahn optional, E „Betreten“); Server prüft Nähe (4 m) und Zugang; Creator-Menüs; Tabellen `elevators`, `portals` |
| `config/peds.lua`, `client/peds.lua`, `server/peds.lua` | NPC-Creator (5.7): Modelle/Szenarien/Aufgaben aus Config, Peds lokal in 120 m gespawnt, E „Ansprechen“ (Reihenfolge 4) ruft die Aufforderung der Aufgabe (`TacoV.Prompt.entries[task]`) auf; Platzierer mit halbtransparenter Vorschau (`previewPed`); Tabelle `peds` |
| `config/world.lua`, `client/world.lua`, `server/world.lua` | Objekt-Placer (5.8: lokale Requisiten, Vorschau `previewProp`, `onGround`) und Zonen (5.9: Kreis/Polygon mit Punkt-in-Polygon-Test, Betreten/Verlassen-Ereignisse und Hinweis, Debug-Anzeige; Server-Abfrage `TacoV.Zones.at(x,y,z,kind)`, `playerIn(src,kind)`, Export `zonesAt`); Tabellen `props`, `zones` |
| `server/admin.lua`, `client/admin.lua` (Fahrzeuge) | 5.10: `tacov:admin:vehicle(action, netId, a, b)` – Server prüft Recht, protokolliert, erledigt DB-Teile (Kennzeichen inkl. `replate`, Löschen setzt Eigentum auf `garage`), Client führt Natives aus (`tacov:admin:vehicle:do`) |
| `server/refunds.lua` | Erstattungen (5.11): Stufen nach `Config.Permissions.refundSmallMax/refundMax` und Item-Kategorie, Vier-Augen (Antragsteller ≠ Bestätiger, `admin.refund.large`), Auszahlung per Journal bzw. Inventar (offline über `Inventory.load`), Tabelle `refunds`, Log `money`/`admin` |
| `server/weather.lua`, `client/weather.lua`, `config/world.lua` (World) | Welt (5.12): Server führt Uhrzeit (`dayMinutes`) und Wetter (gewichtete Liste, `weatherMinutes`), Sync alle 10 s und bei Änderung; `tacov:world:set` (time, timeFreeze, weather, weatherFreeze, announce, restart) mit `admin.world`/`admin.config`; Ansage-Banner `tacov:core:announce` → NUI `announce` |
| `shared/configedit.lua`, `server/configedit.lua`, `client/configedit.lua` | Config im Spiel (5.13): bearbeitbare Wurzeln (`TacoV.ConfigEdit.roots`), Pfadzugriff `get/set` (nur Blattwerte, Typ muss passen), Überschreibungen aus `config_overrides` beim Start und bei Änderung an alle Clients (`tacov:config:overrides`), Ereignis `tacov:config:changed`; Hinweis: Module, die Werte beim Laden in Locals kopieren (z. B. Spieltag-Länge), übernehmen erst nach Neustart |
| `client/creator.lua` (Helfer) | `TacoV.Creator.pickEntity(label, cb)` (Objekt anvisieren), `accessMenu(obj, onSave)`, `accessText`, `fadeTeleport(x,y,z,h)` |
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
- [x] Admin-Grundgerüst (5.1): Unsichtbar, Noclip, Teleport, Team-Menü
- [x] Team-Menü (5.2): Akte, Geben, Heilen, Verwarnen, Kicken, Sperren (Migration 008)
- [x] Orte-Creator (5.3) mit Platzierer und Texteingabe (Migration 009)
- [x] Door Creator (5.4) (Migration 010)
- [x] Elevator Creator (5.5) und Portal Creator (5.6) (Migration 011)
- [x] NPC-Creator (5.7) (Migration 012)
- [x] Objekt-Placer (5.8) und Zonen-Creator (5.9) (Migration 013)
- [x] Fahrzeug-Werkzeuge für das Team (5.10)
- [x] Erstattungen mit Vier-Augen-Prinzip (5.11) (Migration 014)
- [x] Welt-Steuerung (5.12): Uhrzeit, Wetter, Ansagen
- [x] Config im Spiel (5.13) (Migration 015)
- [ ] Fahrzeuge Teil 2c: Blitzer, Kfz-Steuer
- [ ] Einreise-Ablauf mit Teammitglied (Phase 4, Modul Einstieg)
- [ ] Testprotokoll vom Testserver (sobald VPS/Datenbank stehen)
