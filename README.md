# TacoV

Deutscher GTA-V-Roleplay-Server auf FiveM. Eigenes Framework, eigener Code, eigene Oberflächen – nichts übernommen, keine Fremd-Resources. Aufbau des Frameworks: `docs/framework.md`.

## Aufbau

| Ordner | Inhalt |
| --- | --- |
| `server/` | FiveM-Serverdaten: `server.cfg`, Resources unter `resources/[tacov]/` |
| `server/resources/[tacov]/tacov_db/` | Datenbank-Resource (eigener Pool, Exports mit Rückruf) |
| `server/resources/[tacov]/tacov_core/` | Kern: Spieler, Charaktere, Konten, Journal, Rechte, Logs, Bedürfnisse, UI-Brücke, Config |
| `server/resources/[tacov]/tacov_state/` | Staat: Fraktionen, Polizei, Medics, Justiz, Regierung, Werkstatt, Medien |
| `server/resources/[tacov]/tacov_crime/` | Verbrechen: Verarbeitung, Drogen, Waffen, Schwarzgeld, Raub, Gangwar |
| `server/resources/[tacov]/tacov_civ/` | Zivilleben: Handy, Jobs, Fahrzeuge, Bank, Immobilien, Firmen, Freizeit |
| `ui/` | React-Oberfläche (HUD, Menüs, Handy, Tablet, MDT) |
| `bot/` | Discord-Bot (Whitelist, Rollen, Logs, Tickets) |
| `docs/` | Konzept, Entscheidungsprotokoll, Modul-Doku |
| `tools/ci/` | Prüfskripte für die CI |

## Regeln

- Jedes Modul ist eine eigene Resource `tacov_<name>` mit Config, Server- und Client-Teil.
- Spielwerte stehen in Configs, nie im Code. Die CI prüft sie.
- Jede Geld-, Item- und Waffenänderung entscheidet der Server und landet im Journal.
- `main` ist immer spielbar. Jedes Modul ein Branch, jeder PR grün vor dem Merge.

## Entwicklung

Siehe `docs/framework.md` (Aufbau), `docs/entwicklung.md` (Umgebung, VPS) und `docs/entscheidungen.md` (Entscheidungsprotokoll).
