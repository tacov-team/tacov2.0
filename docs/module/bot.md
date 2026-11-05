# Modul: Discord-Bot (`bot/`)

Phase 2. Node.js 20, discord.js 14, mysql2. Siehe `bot/README.md` für Einrichtung.

## Abläufe
1. **Whitelist** – Nutzer reagiert mit dem Emoji auf die Willkommensnachricht → Bot prüft Sperre (`bans`) und Discord-Namen (`name_blocklist`) → Rolle *Whitelist* + Zeile in `whitelist` → Direktnachricht. Abgewiesene bekommen die Reaktion entfernt und eine Direktnachricht mit Grund.
2. **Rollen mitziehen** – Rolle *Whitelist* manuell vergeben/entfernt → Tabelle wird angepasst.
3. **Log-Spiegel** – alle 5 s neue Zeilen aus `logs` in den Kanal der Kategorie (connect, character, money, items, faction, police, medic, justice, crime, admin, support).

## Konfiguration
Geheimnisse (Token, Datenbank) in `bot/.env` (Vorlage `.env.example`, nie eingecheckt). Gilden-, Kanal-, Nachrichten- und Rollen-IDs in `bot/discord.json` (eingecheckt).

## Später (Phase 4/5)
- Rolle *Einwohner* nach erfolgreicher Einreise
- Permatod-Antrag als Ticket
- Supportticket aus `/support` als Thread
