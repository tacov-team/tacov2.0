# TacoV Framework

Eigenes Framework für FiveM, von null gebaut. Kein ESX, kein QBCore, keine Fremd-Resources. Fremdcode gibt es nur als Bibliotheken: `mysql2` (Datenbanktreiber), `react` (Oberfläche), `discord.js` (Bot).

## Schichten

```
┌──────────────────────────────────────────────────────────────┐
│ Module (Phase 3+): inventory, interact, phone, factions, …     │  je ein Ordner unter [tacov]/
├──────────────────────────────────────────────────────────────┤
│ tacov_core  – Spieler, Charaktere, Konten+Journal, Rechte,    │  Lua, Server+Client, eine NUI-Seite
│               Logs, Bedürfnisse, Befehle, UI-Brücke, Config   │
├──────────────────────────────────────────────────────────────┤
│ tacov_db    – Verbindungspool, Exports mit Rückruf            │  JavaScript (Node im FXServer)
├──────────────────────────────────────────────────────────────┤
│ MariaDB     – eine Datenbank, Schema über Migrationen         │
└──────────────────────────────────────────────────────────────┘
                   ↕ Tabellen whitelist/logs           ↕ NUI-Nachrichten
        bot/ (Discord, Node)                      ui/ (React, Build in core/ui)
```

Startreihenfolge regeln die `dependency`-Einträge der Manifeste: `tacov_db` → `tacov_core` → Module. In `server.cfg` steht nur `ensure [tacov]`.

## Grundsätze (aus dem Konzept)

1. **Der Server entscheidet.** Der Client zeigt an und meldet Eingaben; jede Prüfung (Geld, Items, Rechte, Entfernung) passiert serverseitig.
2. **Alle Spielwerte in Configs**, nie im Code. Jede Resource hat `config/*.lua` als `shared_script`; die Werte stammen aus `docs/konzept/*` (dort die Tabellen „Config-Werte“).
3. **Jede Geldbewegung über das Journal** (`TacoV.Journal.move`). Kein Modul schreibt Kontostände direkt.
4. **Logs in Kategorien** (`TacoV.Log.write`), der Bot spiegelt sie in Discord.
5. **Eine NUI-Seite** für alle Oberflächen (React). Lua öffnet Ansichten mit `TacoV.UI.open(view, data)`; Module liefern nur Daten, kein HTML.

## Was der Kern Modulen bietet

### Lua-Namensraum `TacoV` (serverseitig in derselben Resource) bzw. Exports für andere Resources
| Bereich | Funktionen | Export |
| --- | --- | --- |
| Datenbank | `TacoV.DB.query/single/scalar/insert/update/transaction` | nur über Kern |
| Spieler | `TacoV.Players.get(src)`, `.all()`, `.staff(level)` | `getPlayer` |
| Charakter | `TacoV.Characters.get(src)`, `.save(src)`, `.publicData(src)` | `getCharacter` |
| Geld | `TacoV.Journal.move(kind, from, to, amount, reason, opts)`, `.balance(type, id)` | `journalMove`, `journalBalance` |
| Konto | `TacoV.Accounts.pay/receive/tax(src, …)` | `accountPay`, `accountReceive`, `accountTax` |
| Rechte | `TacoV.Permissions.has(src, right)` | `hasPermission` |
| Logs | `TacoV.Log.write(category, text, {characterId, discordId, data})` | – |
| Bedürfnisse | `TacoV.Needs.add(src, key, delta)` | `needsAdd` |
| Bereit | `TacoV.isReady()` + Event `tacov:core:ready` | `isReady` |

### Client
| Bereich | Funktionen |
| --- | --- |
| UI | `TacoV.UI.open(view, data, cursor)`, `.close()`, `.send(action, data)`, `.current()` |
| Spieler | `TacoV.Client.character`, `.role`, `.bank`; Event `tacov:client:characterLoaded` |
| Hinweis | Server: `TriggerClientEvent('tacov:core:notify', src, kind, text)` – kind: success, info, warn, error |

## Konventionen für ein neues Modul

```
server/resources/[tacov]/<name>/
  fxmanifest.lua        name 'tacov_<name>', dependency 'tacov_core'
  config/<name>.lua     shared_script, alle Spielwerte
  server/*.lua          Logik; Events tacov:<name>:<aktion>
  client/*.lua          Anzeige, Eingaben; öffnet Ansichten über exports.tacov_core
  sql/NNN_<name>.sql    eigene Tabellen (Präfix <name>_), vom Kern-Migrationslauf ausgeführt
ui/src/views/<Name>.tsx Ansicht; Registrierung in ui/src/App.tsx
docs/module/<name>.md   Beschreibung, Stand, Testprotokoll
```

- Events heißen `tacov:<modul>:<aktion>`, Befehle sind deutsch und stehen in `config/commands.lua`.
- Serverevents prüfen zuerst `TacoV.Characters.get(source)` und, wo nötig, die Entfernung zum Ziel.
- Items und Fahrzeuge werden mit Konzept-Tabellen abgeglichen (`docs/konzept/items.md`, `orte.md`).
- Definition of Done steht in `docs/entwicklung.md`.

## Datenfluss beim Spielstart

1. `playerConnecting` (core/server/connect.lua): Discord-ID → Sperre → Whitelist → Slots.
2. Client meldet `tacov:core:clientReady` → Server schickt Charakterliste → UI „Charakterauswahl“.
3. Auswahl/Anlage → Server lädt Charakter, bucht ggf. Startgeld über das Journal, sendet `characterLoaded` → Client spawnt, HUD erscheint, Bedürfnisse laufen.
4. Herzschlag alle 10 s (Position, Aktivität), Autosave alle 5 min, Speichern beim Trennen.
