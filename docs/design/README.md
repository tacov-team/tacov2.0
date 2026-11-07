# Design

## Stand V6 „Klar“ (07.11.2026) – Neuaufbau der Oberflächen, gilt für alles Neue

Betreiber: „UIs waren komplett komisch, bau es neu.“ Alle Ansichten neu geschrieben (`ui/src/theme.css`, `views/*`), Daten-Schnittstelle zu Lua unverändert.

- **Maßstab:** alle Größen in `rem`, 1 rem = 1/67,5 der Bildschirmhöhe (16 px bei 1080p) → auf 768p, 1080p, 1440p, 4K identische Proportionen (geprüft 1366×768 und 1920×1080)
- **Flächen:** fast deckendes dunkles Panel (`rgba(14,12,22,0.96)`), 1-px-Rand, Kopfzeile (Icon, Titel, Untertitel, Schließen), Fußzeile für Aktionen; wenig Zierde, hoher Kontrast
- **Akzent:** Violett `#8B5CF6` (Knöpfe, aktive Elemente, Icon-Kacheln), Text `#F5F3FF`; Schwarzgeld Mint; Status-Farben Grün/Gelb/Rot/Blau; Item-Icons in Lavendel/Violett
- **HUD (GLRP-Vorbild, wie in V4 abgenommen):** Logo + Geld (Bargeld, Konto, Schwarzgeld) oben rechts, Hunger/Durst-Kacheln darunter, Funkliste rechts; Infozeilen (ID, Fitness, Fraktion + Rang, Datum/Uhrzeit, Admin-Dienst) rechts neben der Spiel-Minimap; Tacho unten rechts (km/h kursiv, Balkenreihe, Tank, Motor, Schloss) mit Tankstellenkarte darüber
- **Inventar:** zwei gleich große Panels (Taschen | Boden/Behälter), 6 Spalten, Aktionsleiste unten (Auswahl, Menge, Benutzen/Geben/Teilen/Wegwerfen)
- **Bank, Laden, Garage:** ein zentriertes Panel mit klaren Spalten; Listenmenü links; X-Rad mittig; Hinweise oben links; E-Aufforderung unten mittig
- Regel bleibt: neue Oberflächen erst mit ihrem System.


## Stand V5 „Nachtviolett“ (07.11.2026) – gilt für alles Neue

Abgenommen als Punkt 0.15. Aufbau, Schrift und Bedienung von V4 bleiben; neu ist die Farbwelt (`ui/src/theme.css`, alle Farben als Tokens):

- Akzent: Lavendel `#C4A7FF` → Violett `#8B5CF6` → tiefes Violett `#5B21B6` (Verlauf für Knöpfe, Kacheln, Ringe, Tacho); Textakzent `#B794FF`; Hervorhebung Fuchsia `#E879F9` (Geldkarten, Gesamtpreis)
- Fläche: kühles dunkles Glas `rgba(12,10,22,0.88)`, Interaktions-UIs `0.76`; aktive Elemente leuchten violett (`--accent-glow`)
- Schwarzgeld Mint `#5EEAD4`; Erfolg `#34D399`, Fehler `#F05252`, Info `#38BDF8`; gedämpfter Text `#BDB4D6`
- Das Logo bleibt unverändert; neue Farben nie hart in Komponenten, immer über `--accent*`-Tokens
- **Regel des Betreibers:** Neue Oberflächen werden erst gebaut, wenn das zugehörige System dran ist – keine Vorrats-UIs. Tafeln im Canvas dienen nur noch der Abnahme direkt vor der Umsetzung.


## Stand V4 (07.11.2026) – gilt für alles Neue

Vorbild sind die GLRP-Referenzbilder des Betreibers; Tafeln `V4 · …` im Canvas (Reihe ganz unten). Umgesetzt in `ui/src/theme.css`.

- Grund: Panels `rgba(14,12,10,0.86)` mit Kopfzeile (Icon-Kachel, Titel, Info-Zeile, Schraffur-Streifen); Interaktions-UIs (X-Rad, Listenmenü) nutzen `panel soft` mit 0,74 – also leicht durchsichtig wie auf den Bildern
- Akzent: `#FFB800` → `#FF9A1F` (Logo-Gelb/Orange), Textakzent `#FFD54A`; Schwarzgeld Lila `#C9A0FF`
- Schrift: Systemschrift (Segoe UI unter Windows, sonst Inter/Roboto), Zahlen tabellarisch, Tacho kursiv-fett; Akzent-Schriftzug kursiv-leicht in Akzentfarbe (Punkt 3.1: keine Schriftdateien)
- HUD: Logo + Geld oben rechts zentriert untereinander (Bargeld, Konto, Schwarzgeld), darunter Hunger/Durst als Kacheln, rechts die Funkliste (wer gerade funkt); Infozeilen (ID, Fitness, Fraktion + Rang, Datum/Uhrzeit) rechts neben der Vanilla-Minimap; keine Karte in der UI
- HUD Fahrzeug: Tacho unten rechts (km/h, Balkenreihe, Tank in Litern, Motor, Schloss); Tankstellenkarte erscheint darüber
- Bedienung: Listenmenüs nur per Tastatur (↑ ↓ wählen, Enter bestätigen, ⌫ zurück, Esc schließen), Zivilistenaktionen als Unterpunkt des F6-Aktionsmenüs, Werkstatt-Untermenüs Upgrades → Bremsen usw.; Orte/Objekte per E-Ring, X-Rad nur Spieler und Fahrzeuge
- Handy und Laptop: Tafeln V4 · Handy / V4 · Garage (Laptop) als Vorlage, Umsetzung mit dem jeweiligen Modul

## Stand V3 (05.11.2026) – Archiv

Design-Canvas „TacoV Spiel-UI“ (Claude Design, im Projekt verlinkt). Grundlage sind die 27 Grundoberflächen des V3-Designs (Gelb-Orange), die am 05.11.2026 als Basis übernommen wurden.

## Stil (aus der Grundlagen-Tafel)

- Grund: dunkles Braun-Schwarz, radialer Verlauf (#3A3026 → #221C17 → #110E0B)
- Flächen: rgba(12,10,8,0.86) mit innerem Ring rgba(255,184,0,0.18), Radius 12–16 px
- Akzent: Verlauf #FFD54A → #FF9A1F → #F07A12; Textakzent #FFD54A; Warn-Orange #FF9A1F
- Status: Positiv #3FBF5F, Gefahr #E8433A, Info #3B9EFF
- Text: #FFFFFF, gedämpft #C9BFB0, sehr gedämpft #8F8578; Schatten 0 2px 6px rgba(0,0,0,0.8) über Spielszene
- Schrift: Inter 400–900; Zahlen tabellarisch, Tacho kursiv 900
- Ringe: 58 px, Strich 5 px mit Verlauf; Tasten-Hinweise als Verlaufs-Kacheln (kbd)
- Logo: oben rechts im HUD mit Wortmarke ROLEPLAY (docs/design/logo.png)

## Übernommene Tafeln

| Gruppe | Tafeln |
| --- | --- |
| Grundoberflächen | Grundlagen, HUD, HUD Fahrzeug, HUD Bausteine, Interaktionsrad (X), Inventar (F2), Handy (F1), Fraktionsmenü (F6), Team-Menü (F9), MDT, Animationen (F3) |
| UI-Shell | Menü, Formular, Dialog und Bestätigen, Minispiel |
| Start | Ladebildschirm, Charakterauswahl, Charaktereditor, Koma |
| Alltag | Bank, 24/7-Laden, Kleidungsladen, Jobs |
| Fahrzeuge | Autohaus, Garage, Tankstelle, NPC-Werkstatt |

| Staat | Gefängnis (Haft und Terminal), Gericht (Kaution und Verfahren), Rathaus (Bürgerbüro und Lizenzamt), DMV (Führerscheine und Prüfung), MDT Dispatch |
| Untergrund | Überfall-Leiste, Hehler, Schwarzmarkt-Händler, Labor (Camper, Station) |
| Neu | Befehlszeile (T) |

## Anpassungen an Konzept V1 (05.11.2026)

- HUD: fünf Ringe (Leben, Weste, Hunger, Durst, Fitness), Schwarzgeld unter dem Bargeld, Level-Balken einfarbig
- Inventar: Auswahl in der Mitte mit Anzahl (−/+, 1, Hälfte, Alles) und Benutzen, Geben, Teilen, Wegwerfen; kein Schnellzugriff
- Handy: zehn Apps (Kontakte, Nachrichten, Bank, Notruf, Fraktion, Fahrzeuge, Firma, Kamera, Feed, Einstellungen), Funk ausgegraut bis Funkgerät; Notruf nur LSPD und LSMD
- Fraktionsmenü: Reiter Mitglieder, Kasse, Lager, Fahrzeuge, Rechte, Protokoll; Cap 20 für LSPD
- Rathaus: Waffenschein 2.500 $ ab Level 9 mit LSPD-Prüfung; Flugschein statt Pilotenschein

## Noch offen

- Juwelier (Vitrinen, Safe) als eigene Tafel
- Hände hoch (H) braucht keine Tafel, nur eine Animation
- Alle Tafeln tragen noch Beispielwerte aus dem Referenzentwurf; die Konzeptwerte kommen beim Bau aus der Config
