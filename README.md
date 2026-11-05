# TacoV

Deutscher GTA-V-Roleplay-Server auf FiveM. Eigenes Framework, eigener Code, eigene Oberflächen – nichts übernommen.

## Aufbau

| Ordner | Inhalt |
| --- | --- |
| `server/` | FiveM-Serverdaten: `server.cfg`, Resources unter `resources/[tacov]/` |
| `server/resources/[tacov]/core/` | Kern: Spieler, Charaktere, Konten, Items, Rechte, Journal, Config-Lader |
| `server/resources/[tacov]/state/` | Staat: Fraktionen, Polizei, Medics, Justiz, Regierung, Werkstatt, Medien |
| `server/resources/[tacov]/crime/` | Verbrechen: Verarbeitung, Drogen, Waffen, Schwarzgeld, Raub, Gangwar |
| `server/resources/[tacov]/civ/` | Zivilleben: Handy, Jobs, Fahrzeuge, Bank, Immobilien, Firmen, Freizeit |
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

Siehe `docs/entwicklung.md` (lokale Umgebung) und `docs/entscheidungen.md` (Entscheidungsprotokoll).
