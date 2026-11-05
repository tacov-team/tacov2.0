# Design

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
