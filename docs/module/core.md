# Modul: Kern (`tacov_core`)

Phase 2. Grundlage für alle anderen Resources: Datenbank, Spieler, Charaktere, Konten mit Journal, Rechte, Logs, Befehle.

## Dateien
| Datei | Aufgabe |
| --- | --- |
| `config/core.lua` | Slots, Autosave, Charakterplätze, Whitelist-Texte, Einstieg, Level, Bedürfnisse, Inventar, Tasten, Voice |
| `config/economy.lua` | Bank, Steuern, Tanken, Staatshaushalt, Schwarzgeld, Jobs, Gehälter |
| `config/permissions.lua` | Rollen (player/supporter/admin/management) und Rechte |
| `shared/util.lua` | Geld runden, Zahlenbereich, Text bereinigen, Convar |
| `server/db.lua` | Hülle um oxmysql; andere Module nutzen nur `TacoV.DB` |
| `server/migrations.lua` + `sql/NNN_*.sql` | Schema; läuft beim Start, merkt sich Version in `migrations` |
| `server/log.lua` | `TacoV.Log.write(kategorie, text, {characterId, discordId, data})` → Tabelle `logs`, Bot spiegelt in Discord |
| `server/journal.lua` | `TacoV.Journal.move(kind, from, to, amount, reason)` – die einzige Stelle für Geldbewegungen |
| `server/permissions.lua` | `TacoV.Permissions.has(source, recht)` |
| `server/players.lua` | Spielerkonto je Discord-ID, Online-Liste, Teamliste |
| `server/characters.lua` | Liste, Anlage (Namensregeln, Blockliste, 2. Platz ab Level 15), Laden, Speichern, Spielzeit ohne AFK |
| `server/accounts.lua` | `pay`, `receive`, `tax` für andere Module |
| `server/connect.lua` | `playerConnecting`: Discord-ID Pflicht → Sperre → Whitelist → Slots → Doppelverbindung |
| `server/commands.lua` | `/support`, `/ort setzen|liste`, `/rolle`, `/sperre`, `/kick` |
| `server/main.lua` | Startfolge, Autosave, Speichern beim Stop |
| `client/main.lua` | Anmeldung, Spawn nach Charakterwahl, Herzschlag (Position, Aktivität) |
| `client/ui.lua` | NUI-Brücke (`TacoV.UI.open/close/send`) |
| `ui/index.html` | Platzhalter-Charakterauswahl im V3-Stil; wird in Phase 3 durch die React-UI ersetzt |

## Exports für andere Resources
`isReady`, `getPlayer(source)`, `getCharacter(source)`, `hasPermission(source, recht)`, `journalMove(...)`, `journalBalance(ownerType, ownerId)`, `accountPay/accountReceive/accountTax`.

## Events
- Server → Client: `tacov:core:characters`, `tacov:core:characterLoaded`, `tacov:core:bank`, `tacov:core:notify`, `tacov:core:role`
- Client → Server: `tacov:core:clientReady`, `tacov:core:selectCharacter`, `tacov:core:createCharacter`, `tacov:core:heartbeat`
- Serverintern: `tacov:core:ready`, `tacov:core:locationChanged`

## Tabellen (Migration 001)
`migrations`, `whitelist`, `players`, `bans`, `characters`, `accounts`, `journal`, `logs`, `name_blocklist`, `locations`

## Abhängigkeit
`oxmysql` (MIT) unter `server/resources/[external]/oxmysql`; `ensure oxmysql` vor `ensure [tacov]`.

## Stand
- [x] Schema, DB-Hülle, Migrationen
- [x] Whitelist-Prüfung beim Verbinden
- [x] Spieler, Charaktere (2 Plätze), Spielzeit, Autosave
- [x] Konten über Journal, Startgeld
- [x] Rechte, Grundbefehle
- [ ] Einreise-Ablauf mit Teammitglied (Phase 4, Modul Einstieg)
- [ ] Testprotokoll vom Testserver (sobald VPS/Datenbank stehen)
