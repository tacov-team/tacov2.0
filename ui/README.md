# UI

React 19 + TypeScript, gebaut mit esbuild (kein Vite nötig). Stil nach `docs/design/README.md`, Boards aus dem Canvas „TacoV Spiel-UI“.

```bash
cd ui
npm install
npm run build      # -> server/resources/[tacov]/tacov_core/ui/ (app.js, app.css, index.html, assets/)
npm run watch      # Entwicklung
```
Der Build ist eingecheckt, damit der VPS nach `git pull` sofort spielbar ist; `tools/vps/deploy.sh` baut trotzdem neu.

Vorschau ohne Spiel: `server/resources/[tacov]/tacov_core/ui/index.html` im Browser öffnen – zeigt Beispielwerte. Tasten: **T** Befehlszeile, **C** Charakterauswahl, **I** Inventar, **X** Interaktionsrad, **B** Bank, **S** Laden, **M** Aktionsmenü, **Shift+M** Untermenü, **V** Fahrzeug-HUD an, **Shift+V** aus.

## Schrift
Die UI nutzt die Systemschrift (Segoe UI unter Windows, sonst Inter/Roboto) – keine Schriftdateien nötig (Punkt 3.1).

## Item-Icons
`ui/public/items/<item>.svg` werden von `python3 ui/tools/make-item-icons.py` erzeugt (Linien-Icons im UI-Stil). Ein eigenes Bild ersetzt das Icon ohne Codeänderung: `ui/public/items/<item>.png` (128×128, transparent) ablegen, `npm run build`. Fehlt beides, zeigt die UI das Kategorie-Symbol. Welche Datei je Item aktiv ist, trägt der Build in die App ein (zusätzlich `assets/items/index.json`).

## Aufbau
| Datei | Inhalt |
| --- | --- |
| `src/nui.ts` | `nui(name, data)` ruft Lua-Callbacks, `useNuiEvent` empfängt `SendNUIMessage` |
| `src/store.tsx` | Zustand: HUD, Ansicht, Hinweise, Rolle |
| `src/theme.css` | V6-Stil: rem-Maßstab (1 rem = Bildschirmhöhe/67,5), Farben, Panels, Buttons, Listen, Layout aller Ansichten |
| `src/components/Panel.tsx` | `Panel` (Kopf mit Icon/Titel/Untertitel/Schließen, Körper, Fuß), `Kbd` |
| `src/components/Icon.tsx` | Linien-Icons (`<Icon name="fuel" />`) |
| `src/views/Hud.tsx` | HUD: Logo, Geld, Hunger/Durst, Funkliste, Infozeilen neben der Minimap, Fahrzeug-Tacho, Tankstellenkarte |
| `src/views/Toasts.tsx` | Hinweise oben links (Erfolg, Info, Warnung, Fehler) |
| `src/views/Console.tsx` | Befehlszeile (T) mit Vorschlägen und Verlauf |
| `src/views/Characters.tsx` | Charakterauswahl und -anlage |
| `src/views/Menu.tsx` | Listenmenü per Tastatur (Lua: `TacoV.Menu.open`) |
| `src/views/Wheel.tsx` | Interaktionsrad (X) – nur Spieler und Fahrzeuge |
| `src/views/Inventory.tsx` | Inventar (F2): Taschen · Auswahl · Boden/Gegenüber |
| `src/views/Bank.tsx`, `Shop.tsx` | Bank/Geldautomat, Läden |
| `src/views/Garage.tsx` | Garage/Verwahrhof: Suche, Filter, Fahrzeugkarten (Taste **G** in der Vorschau) |
| `src/views/Dealer.tsx` | Kaufhaus: Klassen-Reiter, Fahrzeugkarten, Details, Bar/Karte; Panel links, Vorschau im Spiel rechts (Taste **D**) |

## Nachrichten Lua → UI
`open {view, data}`, `close`, `hud {…}` (u. a. `vehicle {speed, fuel, tank, engine, locked}` oder `false`, `station {name, sub, price}`, `radio [{id, name, talking}]`), `bank`, `role`, `hint {key, text}`, `notify {kind, title?, text}`

## Callbacks UI → Lua
`close`, `command {command}`, `selectCharacter {id}`, `createCharacter {…}`, `action {view, action, data}` → Lua-Event `tacov:ui:<view>:<action>` (Menü: `select {menu, id}`, `back`, `close`)
