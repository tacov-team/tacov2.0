# UI

React 19 + TypeScript, gebaut mit esbuild (kein Vite nötig). Stil nach `docs/design/README.md`, Boards aus dem Canvas „TacoV Spiel-UI“.

```bash
cd ui
npm install
npm run build      # -> server/resources/[tacov]/tacov_core/ui/ (app.js, app.css, index.html, assets/)
npm run watch      # Entwicklung
```
Der Build ist eingecheckt, damit der VPS nach `git pull` sofort spielbar ist; `tools/vps/deploy.sh` baut trotzdem neu.

Vorschau ohne Spiel: `server/resources/[tacov]/tacov_core/ui/index.html` im Browser öffnen – zeigt Beispielwerte; Taste **T** öffnet die Befehlszeile, **C** die Charakterauswahl.

## Aufbau
| Datei | Inhalt |
| --- | --- |
| `src/nui.ts` | `nui(name, data)` ruft Lua-Callbacks, `useNuiEvent` empfängt `SendNUIMessage` |
| `src/store.tsx` | Zustand: HUD, Ansicht, Hinweise, Rolle |
| `src/theme.css` | Farben, Flächen, Buttons, Layout aller Ansichten |
| `src/views/Hud.tsx` | HUD: Logo, Geld, fünf Ringe, Karte mit Name/Level, Zeit/Straße/Fraktion/Gewicht |
| `src/views/Toasts.tsx` | Hinweise oben links (Erfolg, Info, Warnung, Fehler) |
| `src/views/Console.tsx` | Befehlszeile (T) mit Vorschlägen und Verlauf |
| `src/views/Characters.tsx` | Charakterauswahl und -anlage |

## Nachrichten Lua → UI
`open {view, data}`, `close`, `hud {…}`, `bank`, `role`, `notify {kind, title?, text}`

## Callbacks UI → Lua
`close`, `command {command}`, `selectCharacter {id}`, `createCharacter {…}`
