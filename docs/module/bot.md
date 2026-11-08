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

## Team-Rollen (Punkt 0.11)
`src/teamroles.js` spiegelt die Discord-Team-Rollen nach `players.role`: beim Start alle Mitglieder, danach bei jeder Rollenänderung (`guildMemberUpdate`) und beim Verlassen. Höchste Rolle gewinnt; ohne Team-Rolle wird der Spieler wieder `player`. Die Rollen-IDs stehen in `discord.json` unter `teamRoles` (leer = nicht gespiegelt). Im Spiel gelten die Rechte nur im Admin-Dienst (F9 / `/aduty`).

## Status-Embed und Ansagen (Punkte 1.7, 1.9)
`src/status.js` postet einmal ein Embed in den Kanal „Server Status“ (`statusChannelId` in `discord.json`) und bearbeitet es alle 30 s: online/offline (Zeile `server_status` älter als 90 s = offline), Spieler/Slots, nächster Neustart, Laufzeit, Version (aus `version.json`, vom Deploy geschrieben). Die Nachrichten-ID steht in `bot_state`. Ansagen aus `announcements` (Neustart-Warnungen, `/neustart`) werden in denselben Kanal gepostet.

## TeamSpeak-Embed (Punkt 1.10)
`src/teamspeak.js` fragt alle 30 s den ServerQuery (127.0.0.1:10011, `TS_QUERY_PASS` aus `.env`, von `setup-teamspeak.sh` eingetragen) ab und bearbeitet ein zweites Embed im Status-Kanal: online/offline, Adresse (`TS_ADDRESS`), Verbundene/Max, Laufzeit, Namen der Verbundenen. Nachrichten-ID in `bot_state` (`ts_status_message_id`).

## Tickets (Punkt 5.15, `src/tickets.js`)
- Alle 10 s: neue Tickets → Textkanal `ticket-<id>-<name>` in der Kategorie `ticketsCategoryId` (Team-Rollen und der Spieler sehen ihn), Embed mit Anliegen; Spiel-/Systemnachrichten → Kanal; geschlossene Tickets → Kanal `geschlossen-<id>`, Schreiben gesperrt.
- Nachrichten im Kanal → `ticket_messages` (source `discord`), der Spielserver zeigt sie dem Spieler; `!schliessen` schließt das Ticket.
- Braucht die Intents `GuildMessages` und `MessageContent` (Message Content Intent im Discord-Entwicklerportal aktivieren!).

## Anti-Cheat-Meldungen (Punkt 5.16)
- `anticheat.roleId` wird bei Meldungen erwähnt, `anticheat.channelId` erhält die Meldung mit allen Infos.
