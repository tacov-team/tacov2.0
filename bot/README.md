# TacoV Discord-Bot

Node.js 20+, discord.js. Teilt sich die Datenbank mit dem Spielserver.

## Aufgaben (Phase 2)
- **Whitelist**: Reaktion auf die Willkommensnachricht → Sperre prüfen → Name gegen Blockliste → Rolle *Whitelist* + Zeile in `whitelist`. Der Spielserver lässt nur Discord-IDs aus dieser Tabelle herein.
- **Rollen**: Wer die Rolle *Whitelist* manuell bekommt oder verliert, wird mitgezogen.
- **Log-Kanäle**: Neue Zeilen aus `logs` landen in den konfigurierten Kanälen (11 Kategorien).

## Einrichten
```bash
cd bot
cp .env.example .env     # Token + Datenbank, nie einchecken
npm install
npm start
```
Kanal- und Rollen-IDs stehen in `discord.json` (eingecheckt, keine Geheimnisse). IDs holen: Discord → Einstellungen → Erweitert → Entwicklermodus, dann Rechtsklick auf Kanal/Rolle/Nachricht → „ID kopieren“.
Im Discord Developer Portal muss der *Server Members Intent* aktiv sein (für Rollen); *Message Content* wird nicht gebraucht. Der Bot braucht in der Gilde: Rollen verwalten, Nachrichten lesen/senden, Reaktionen verwalten. Die Rolle des Bots muss über der Rolle *Whitelist* stehen.

## Dauerbetrieb auf dem VPS
`pm2 start src/index.js --name tacov-bot` oder ein systemd-Dienst; Logs über `pm2 logs tacov-bot`.
