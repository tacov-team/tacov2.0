# TacoV · Entwicklungspunkte

Stand: 08.11.2026. Der Phasenplan (`docs/phasenplan.md`) in einzelne Punkte zerlegt. **Ein Punkt = ein System**, wir arbeiten sie der Reihe nach ab, von vorn. Jeder Punkt wird erst „✅ abgenommen“, wenn der Betreiber ihn bestätigt hat – auch die bereits gebauten. Das Protokoll der Bestätigungen steht in `docs/entscheidungen.md`.

Status: ⬜ offen · 🔧 gebaut, noch nicht abgenommen · ✅ abgenommen · ⏸ zurückgestellt

**Arbeitsweise (seit 08.11.2026):** Zu Beginn jeder Phase erklärt Claude zuerst, wie die Punkte gebaut werden sollen, nennt offene Entscheidungen und wartet auf das Einverständnis des Betreibers; erst dann wird gebaut.

## Phase 0 · Konzept und Grundentscheidungen

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 0.1 | Servername, Slots, Sprache, Setting | ✅ | Name TacoV, 10 Slots, Deutsch, Los Santos Gegenwart (bestätigt 07.11.) |
| 0.2 | Leitbild und Grundsätze | ✅ | Sechs Grundsätze (Konzept 1.1) |
| 0.3 | Weg zum Server (Discord, Whitelist) | ✅ | Reaktion = Whitelist, Discord-ID als Anker |
| 0.4 | Einreise, Neulingspfad, Level/Probezeit | ✅ | Einreise mit Teammitglied, Startgeld 5.000 $, Level 3/8/15 |
| 0.5 | Fraktionen zum Start und ihre Regeln | ✅ | LSPD, LSMD, DMV, Regierung, DOJ, eine Streetgang; Caps |
| 0.6 | Wirtschaft: Geldkreislauf, Jobs, Bank, Steuern | ✅ | 6 Jobs, Steuern 8 %, Kaufzeiten 10/40/80/200 h |
| 0.7 | Wirtschaft: Fahrzeuge, Immobilien, Firmen | ✅ | Klassen, Garagen, Burger Shot |
| 0.8 | Verbrechen und Justiz | ✅ | Drogen, Waffen, Raub, Strafkatalog, Haft, Koma |
| 0.9 | Alltag und Handy | ✅ | Inventar, Bedürfnisse, 10 Apps, Interaktion, Läden |
| 0.10 | Items- und Orte-Tabellen | ✅ | `docs/konzept/items.md`, `orte.md` |
| 0.11 | Team-Rollen und Rechte | ✅ | 10 Discord-Rollen, Rechte je Stufe, Aduty (bestätigt 07.11.; Rollen-IDs in `bot/discord.json` eingetragen) |
| 0.12 | Anti-Cheat-Ansatz | ✅ | eigener Abgleich im Kern (Punkt 5.16), kommerziell erst ab > 32 Slots (bestätigt 07.11.) |
| 0.13 | Hoster, Testserver, Neustart-Fenster | ✅ | Testserver auf dem VPS (develop), Neustart alle 6 h, Backup täglich, Status-Embed in Discord (bestätigt 07.11.) |
| 0.14 | Voice (TeamSpeak-Plugin, Lizenz) | ✅ | SaltyChat / TeamSpeak 3 (bestätigt 07.11.) |
| 0.15 | Design-Richtung (V5 „Nachtviolett“, Barlow, Listenmenüs) | ✅ | `docs/design/README.md`; neue UIs erst mit ihrem System (bestätigt 07.11.) |
| 0.16 | Spielstil: Softcore/Midcore, Bodyshot | ✅ | Konzept 1.2; Bodyshot im Kern umgesetzt (07.11.) |

## Phase 1 · Infrastruktur

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 1.1 | Repo, Branching, CI (luacheck, Struktur, Geheimnisse) | ✅ | `tacov-team/tacov2.0`, `.github/workflows` |
| 1.2 | VPS-Einrichtung (`/opt/tacov2`, Nutzer, MariaDB, phpMyAdmin) | ✅ | `tools/vps/setup.sh` |
| 1.3 | FXServer-Betrieb (screen, Dienste, Artefakt-Update, Deploy) | ✅ | `deploy.sh`, `fx-update.sh` |
| 1.4 | Discord-Bot: Whitelist per Reaktion | ✅ | `bot/` |
| 1.5 | Discord-Bot: Log-Spiegel (11 Kanäle) | ✅ | |
| 1.6 | Geheimnisse und Zugänge (server.cfg, .env, CI-Prüfung) | ✅ | |
| 1.7 | Backups und Monitoring | ✅ | DB-Backup täglich 05:30 + vor Deploy, 14 Tage; Status-Embed im Discord-Kanal „Server Status“ |
| 1.8 | Testserver-Instanz (`/opt/tacov2-test`, Branch develop, Port 30122) | ✅ | `setup-test.sh`, `deploy-test.sh`; zweiter Keymaster-Schlüssel nötig |
| 1.9 | Neustart alle 6 h mit Ansagen 15/5/1 min | ✅ | `server/status.lua`, `/neustart <Minuten>` |
| 1.10 | TeamSpeak-3-Server auf dem VPS (Non-Profit-Lizenz beantragen), SaltyChat-Resource einbinden | ✅ | läuft (07.11.); TeamSpeak-Embed im Status-Kanal; offen beim Betreiber: Lizenz + SaltyChat-Freischaltung |

## Phase 2 · Kern (eigenes Framework)

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 2.1 | Datenbank-Resource `tacov_db` und `TacoV.DB` | ✅ | mysql2 im FXServer-Node, Migrationen |
| 2.2 | Spieler und Verbindung (Discord-ID, Whitelist-Prüfung, Sperren) | ✅ | |
| 2.3 | Charaktere (1 Platz, Anlage, Auswahl, Autosave) | ✅ | |
| 2.4 | Journal als einziger Geldweg, Konten | ✅ | |
| 2.5 | Rechte und Rollen | ✅ | |
| 2.6 | Logs (Kategorien, Spiegel in Discord) | ✅ | |
| 2.7 | Befehlszeile (T) und Befehle | ✅ | |
| 2.8 | Orte (Config + `/ort setzen`, Blips) | ✅ | |
| 2.9 | Spielzeit, Level, Probezeit | ✅ | |
| 2.10 | Tastenbelegung und Interaktion (E-Aufforderung, X-Rad, Listenmenü) | ✅ | |
| 2.11 | Schadensmodell Bodyshot | ✅ | `client/main.lua` |

## Phase 3 · Alltag I

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 3.1 | Oberfläche V6 „Klar“: Grundlagen, Panels, Maßstab | ✅ | Neuaufbau 07.11., zur Abnahme auf dem Testserver |
| 3.2 | HUD (Geld, Hunger/Durst, Funkliste, Infozeilen, Tacho) | ✅ | |
| 3.3 | Hinweise (Toasts) | ✅ | |
| 3.4 | Charakterauswahl | ✅ | |
| 3.5 | Inventar (F2), Ablagen, Items, Icons | ✅ | |
| 3.6 | Bedürfnisse Hunger/Durst | ✅ | Fitness und Promille: Phase 5/10 |
| 3.7 | Hände hoch (H) | ✅ | |
| 3.8 | Bank und Geldautomat | ✅ | |
| 3.9 | Läden (24/7, LTD, Rob's, Baumarkt, Waffenladen) | ✅ | |

## Phase 4 · Fahrzeuge

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 4.1 | Fahrzeugklassen und Kaufliste | ✅ | 8 Klassen, 52 Modelle, kein Level |
| 4.2 | Kaufhäuser (PDM, LKW) mit Vorschau und Kamera | ✅ | Kaufhaus-Ansicht mit Karten (07.11.) |
| 4.3 | Garagen (alle Parkplätze) und Garage-Ansicht | ✅ | Ausfahrten im Spiel prüfen |
| 4.4 | Verwahrhof | ✅ | |
| 4.5 | Schlüssel, Schloss, Schlüssel geben | ✅ | |
| 4.6 | Kofferraum und Handschuhfach | ✅ | außen Kofferraum (offen = für alle), innen Handschuhfach 5 kg |
| 4.7 | Tanken und Verbrauch, Tankstellenkarte | ✅ | |
| 4.8 | Fahrzeugmenü (F6 → Fahrzeug, X-Rad) | ✅ | Motor startet nicht automatisch |
| 4.9 | DMV: Zulassung, Halterwechsel | ✅ | DMV Vespucci; TMP-Kennzeichen bis Zulassung |
| 4.10 | Fahrschule: Theorie, Praxis, Führerschein A/B/C, Punkte | ✅ | B 500 / A 350 / C 800 $, Wiederholung 100 $; Kauf nur mit Führerschein; Prüfungsfahrzeug C = LKW (Mule), Kontrollpunkte springen auf die nächste Fahrbahn |
| 4.11 | NPC-Werkstatt: Reparatur, Upgrades, Zubehör | ✅ | 5 Werkstätten; Leistung 5/10/20 % vom Kaufpreis; Karosserie (Spoiler, Stoßstangen, Schweller, Auspuff, Käfig, Grill, Haube, Kotflügel, Dach, Hupe, Folierung) 150–900 $; Felgen alle Arten/Modelle 800 $, Felgenfarbe 250 $; Lack Haupt/Zweit/Perlglanz 500 $ (28 Farben), Fenster 300 $, Xenon 600 $, Kennzeichenstil 200 $; **Live-Vorschau beim Markieren**, ohne Kauf zurückgesetzt |
| 4.12 | Blitzer | ✅ | 6 Blitzer (Olympic Fwy, Del Perro Fwy, Vinewood Blvd, Great Ocean Hwy, Route 68, Senora Fwy), Toleranz 5 km/h, Bußgeld 100–2000 $, ab 21 km/h Punkte; Orte per `/ort setzen blitzer_<n> speedcam` |
| 4.13 | Kfz-Steuer | ✅ | 1 % des Kaufpreises je Jahr, wöchentlich anteilig vom Bankkonto (auch offline); offen → fällig beim Ausparken |
| 4.14 | Boote und Flugzeuge | ⏸ | Entscheidung später |

## Phase 5 · Entwickler- und Admin-Werkzeuge (Creator-Systeme)

Alles, was Team und Entwicklung brauchen, um Inhalte ohne Code-Änderung zu setzen und den Server zu verwalten. Jedes Creator-System speichert in der Datenbank, hat Rechte je Rolle und wird im Log protokolliert.

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 5.1 | Admin-Grundgerüst: Rechte, Admin-Modus, Unsichtbar, Noclip, Teleport (Spieler/Koordinaten/Wegpunkt) | ✅ | F9 im Dienst = Team-Menü (Unsichtbar, Noclip, Teleport Wegpunkt/zu Spieler/herholen, Dienst beenden); `/tp`, `/tpm`, `/bring`, `/noclip`, `/unsichtbar`; Dienst-Uniform automatisch (Config `AdutyOutfit`); alles geloggt |
| 5.2 | Team-Menü (F9): Spielerliste mit Akte, Items/Geld/Fahrzeug geben, Heilen, Kicken, Sperren, Warnen | ✅ | Team-Menü → Spieler → Akte (Rolle, Charakter, Konto, Verwarnungen/Sperren, Führerscheine) + Aktionen; Gründe/Dauern aus Config, freier Text per `/warn`, `/kick`, `/sperre`; Tabelle `warnings` (Migration 008); jede Aktion mit Log |
| 5.3 | Orte-Creator: Orte, Blips, E-Punkte im Spiel setzen und verschieben (ersetzt `/ort setzen`) | ✅ | Team-Menü → Creator → Orte: neu (Art, Platzieren am Zeiger, Name, Beschriftung), in der Nähe/alle bearbeiten (verschieben, Beschriftung, Art, Blip aus, Ausfahrt/Vorschau, Tempolimit, löschen); Platzierer mit Leertaste Zeiger/fest, Pfeile/Bild↑↓, Q/E, Shift; Migration 009 |
| 5.4 | Door Creator: Türen und Tore erfassen, Zugang je Fraktion/Rang/Schlüssel, Zustand (offen/zu) | ✅ | Creator → Türen: Tür anvisieren + Enter (zweiter Flügel optional), Zugang Fraktion+Mindestrang oder Schlüssel-Item oder frei, Auto-Schließen, Teile ergänzen; E am Türrahmen schließt auf/ab, synchron für alle; Team im Dienst öffnet alles; Tabelle `doors` (Migration 010) |
| 5.5 | Elevator Creator: Aufzüge mit Etagen, Zugang, Teleport mit Blende | ✅ | Creator → Aufzüge: Bezeichnung, Etagen nacheinander platzieren und benennen; E am Etagenpunkt → Etagenwahl → Blende; Zugang wie Türen; Etagen ergänzen/verschieben/entfernen; Tabelle `elevators` (Migration 011) |
| 5.6 | Teleport-/Portal-Creator: Ein-/Ausgänge für Interiors (z. B. Polizeiwache, Wohnungen) | ✅ | Creator → Portale: Eingang und Ausgang platzieren, beide Richtungen oder Einbahn, Zugang wie Türen; E „Betreten“ mit Blende; Tabelle `portals` (Migration 011) |
| 5.7 | Ped-/NPC-Creator: Ansprechpartner mit Modell, Animation, Aufgabe (Shop, Job, Kaufhaus) | ✅ | Creator → NPCs: 20 Modelle + freie Eingabe, Vorschau am Zeiger, 15 Szenarien, Aufgabe (Laden, Bank, Kaufhaus, DMV, Garage, Werkstatt, Tankstelle) – E „Ansprechen“ löst sie aus, wenn der NPC am Ort steht; lokal gespawnt (unverwundbar, eingefroren); Tabelle `peds` (Migration 012) |
| 5.8 | Objekt-Placer: Requisiten setzen, drehen, speichern (Schranken, Container, Möbel-Grundlage) | ✅ | Creator → Objekte: 18 Requisiten + freie Eingabe, Vorschau am Zeiger, Q/E drehen, auf Boden ausrichten; lokal gespawnt in 200 m; Tabelle `props` (Migration 013) |
| 5.9 | Zonen-Creator: Bereiche (Polygon/Kreis) für Gebiete, Sicherheitszonen, Jobs | ✅ | Creator → Zonen: Art (Sicherheitszone, Job, Gebiet, Fahrzeugverbot, Sonstiges), Kreis (Mittelpunkt+Radius) oder Polygon (Punkte ablaufen), Höhenbereich, Anzeige ein/aus; Client-Ereignisse `tacov:zone:enter/leave`, `TacoV.Zones.inside(kind)`; Server `TacoV.Zones.at/playerIn`; Tabelle `zones` |
| 5.10 | Fahrzeug-Spawner und Fahrzeug-Editor für das Team (Modell, Kennzeichen, Tuning) | ✅ | Team-Menü → Fahrzeuge: Team-Fahrzeug spawnen (Klasse/Modell oder Eingabe, Kennzeichen TEAM xxx, temporär), aktuelles/nahes Fahrzeug: Besitzer, Reparieren, Volltanken, Kennzeichen, Voll tunen, Farbe, Fensterfarbe, Löschen (Eigentum geht in die Garage zurück); leere Fahrzeuge im Umkreis löschen; Rechte `admin.vehicle(.spawn)` |
| 5.11 | Item- und Geld-Werkzeuge mit Vier-Augen-Prinzip (Erstattung) | ✅ | Akte → Erstattung (Geld oder Item, Grund Pflicht): bis 10.000 $ ab Moderator sofort, bis 50.000 $ ab Superadmin sofort, darüber sowie Waffen/Schutz/Munition nur mit Bestätigung einer zweiten Person ab Manager (Team-Menü → Offene Erstattungen); Auszahlung auch offline; Tabelle `refunds` (Migration 014) |
| 5.12 | Welt-Steuerung: Wetter, Uhrzeit, Ansagen, Neustart-Ankündigung | ✅ | Uhrzeit/Wetter kommen vom Server (Spieltag 120 min, Wetterwechsel alle 25 min, gewichtet); Team-Menü → Welt: Uhrzeit setzen/einfrieren, Wetter setzen/einfrieren (inkl. Schnee/Schneesturm), **Schnee ein/aus** (Schneedecke, Spuren, Effekte), Ansage (Banner oben für alle), Neustart ankündigen; Neustart-Warnungen ebenfalls als Banner |
| 5.13 | Config im Spiel: Werte lesen und ändern (Management), Änderung geloggt | ✅ | Team-Menü → Config: 15 Bereiche (Wirtschaft, Gehälter, Hunger/Durst, Level, Blitzer/Steuer, DMV, Werkstatt, Fahrzeugklassen, Inventar, Welt, Neustart, Team-Grenzen, Stimme, Einstieg, Status) durchblättern, Zahlen/Texte/Schalter ändern oder zurücksetzen; Überschreibungen in `config_overrides` (Migration 015), gelten sofort auf Server und Clients; Log `admin` |
| 5.14 | Entwickler-Werkzeuge: Koordinaten anzeigen/kopieren, Entity-Info, Debug-Zonen, Hot-Reload der Config | ✅ | Team-Menü → Entwickler (`dev.tools`): Koordinaten-Overlay (Position, Heading, Fahrzeug, Zone/Straße), Entity-Info am Zeiger (Typ, Modell, Netz-ID, Leben/Kennzeichen), Zonen- und Orte-Anzeige, Position kopieren (`/coords`, Zwischenablage), Entity-Besitzer, Daten/Überschreibungen neu laden (`tacov:core:reloadData`), Kern-Resource neu starten (speichert vorher) |
| 5.15 | Spieler-Akte und Tickets (`/support`) mit Bearbeitung im Spiel und Discord | ✅ | `/support <Text>` legt Ticket an (weitere Texte ergänzen es); Team-Menü → Tickets: übernehmen, antworten, hingehen, schließen; Bot legt je Ticket einen Kanal in Kategorie 1568940600257150976 an (Team + Spieler sehen ihn), spiegelt Spielnachrichten, Antworten aus Discord erreichen den Spieler im Spiel, `!schliessen` schließt; Tabellen `tickets`, `ticket_messages` (Migration 016); Akte siehe 5.2 |
| 5.16 | Anti-Cheat-Grundlage: Abgleich Geld/Items/Geschwindigkeit/Entities, Meldungen ans Team | ✅ | Server prüft Bewegung (zu Fuß > 28 m/s, Fahrzeug > 450 km/h; 3 Auffälligkeiten/60 s → Kick), Bargeld vs. Journal (+1.000 Hinweis, +50.000 Kick), Explosionen (≥ 3/10 s → Kick), Entity-Flut (≥ 25 Skript-Entities/10 s, Verkehr zählt nicht) und verbotene Objekte; dritter eindeutiger Fall binnen 24 h → 72 h Sicherheitssperre; `/entsperren <Discord-ID>`; Meldungen in `ac_reports` (Migration 017), Team im Dienst sofort, Bot → Kanal 1568941437255688212 mit Rolle 1568019443165036564; Team-Menü → Anti-Cheat; Test: `/actest` |

## Phase 6 · Charakter und Einstieg

| Nr. | Punkt | Status | Inhalt / Abnahme |
| --- | --- | --- | --- |
| 6.1 | Charaktereditor (Gesicht, Haare, Farben) | ✅ | Nach Name/Geburtsdatum öffnet der Editor **in eigener Welt** (Routing-Bucket je Spieler – niemand sieht oder stört; erst „Charakter anlegen“ setzt ihn an den Flughafen, den er bis zur Einreise nicht verlässt) (Figur in der Ankunftshalle, Kamera Gesicht/Körper, ←/→ drehen): Geschlecht, Eltern (46 Vorlagen), Ähnlichkeit/Hautton, Augenfarbe, 20 Gesichtszüge, Frisur/Farbe/Strähnen, Bart/Brauen/Brustbehaarung, Alterung/Teint/Sonne/Sommersprossen/Hautunreinheiten, Make-up/Rouge/Lippenstift, Zufall; gespeichert in `appearance`, beim Laden angewendet |
| 6.2 | Kleiderläden und Outfits | ✅ | 15 Läden (Konzept-Orte): Editor-Reiter Kleidung (Oberteil, Unterhemd, Arme, Hose, Schuhe, Weste, Tasche, Maske, Aufdruck) und Zubehör (Accessoire, Hut, Brille, Ohrringe, Uhr, Armband) mit Varianten und Live-Preis – nur Geändertes wird berechnet (Preise je Kategorie, Config `Clothing.prices`), Karte/Bar; 10 Outfits je Charakter (nur im Laden und am Kleiderschrank der Wohnung); Maske → Ausweis nicht zuzuordnen; Tabelle `outfits` (Migration 018) |
| 6.3 | Friseur, Tattoo, Chirurg | ✅ | Friseur (7 Orte): Reiter Haare/Details, Preis je geänderter Kategorie (Frisur 40, Bart 20, Brauen 15, Make-up 25 …); Chirurg Pillbox: Herkunft/Gesicht für 5.000 $ einmal je 30 Tage; Tattoo-Studios (6 Orte): Reiter Tattoos mit 48 Motiven (Beach, Business, Lowrider, Biker, Hipster; M/F-Varianten), Vorschau beim Anklicken, nur neue Tattoos kosten (180–300 $), Entfernen kostenlos |
| 6.4 | Ladebildschirm und Einreise mit Teammitglied | ✅ | Eigener Ladebildschirm (Logo, Fortschritt, wechselnde Tipps, Hintergrundmusik als unsichtbares YouTube-Video in Schleife – Video-ID und Lautstärke oben in `loadscreen/index.html` (`MUSIC`), M oder Klick schaltet stumm); neuer Charakter hat nur Reisepass und bleibt im Umkreis der Ankunftshalle (140 m, sanfte Rückführung, HUD-Hinweis); Team-Menü → Einreise: Warteschlange, hingehen/holen, bestanden (Ausweis, 5.000 $, Handy, Wohnungsschlüssel, Busticket, Stadtplan) oder nicht bestanden mit Grund (Rückflug = Kick, Charakter 24 h gesperrt); Recht `immigration` |
| 6.5 | Neulingspfad und Sozialwohnung (Grundlage) | ✅ | Sozialwohnung mit der Einreise (Tabelle `homes`): Haustür Vespucci (Ort `social_housing`, verschiebbar), eigene Instanz je Mieter (Routing-Bucket), drinnen Ausgang, Lager 20 kg, Kleiderschrank (Outfits); 14 Tage frei, danach 300 $/Woche vom Konto, offen → beim Betreten fällig; Neulingspfad: 10 Schritte mit Bonus (F4 → Aktionen), Schritte Wohnung/Führerschein/Kaufhaus/Bank/Kleidung/Essen/Level 3 melden sich automatisch, Job/Notruf/Fraktion folgen mit ihren Phasen |
| 6.6 | Animationsmenü (F3) | ✅ | 47 eigene Einträge in 6 Kategorien (Begrüßung/Gesten, Haltung, Sitzen/Liegen, Tanzen, Arbeit, Alltag) aus Grundspiel-Animationen und Szenarien; Favoriten oben (lokal gespeichert); Gesten laufen beim Gehen weiter, Ganzkörper endet bei Bewegung; F3 oder `/stopanim` beendet |
| 6.7 | Voice (SaltyChat): Sprechweiten 3/10/25 m, HUD-Anzeige, Megafon | ✅ | Sprechweite per Z, der Server setzt die Stufe über SaltyChats Export `SetPlayerVoiceRange` (kein Client-Statebag, kein Echo), HUD folgt `SaltyChat_VoiceRangeChanged`; SaltyChat-Tasten über `tools/vps/salty-config.sh` (eigener Umschalter ohne Taste), `/voicetest` zur Diagnose; Megafon: Alt halten in Einsatzfahrzeugen (Klasse 18, vorne) über `SaltyChat_IsUsingMegaphone`, HUD zeigt MEGA; Telefon/Funk folgen in Phase 7 |
| 6.8 | Verletzungen und Erste Hilfe | ✅ | Bodyshot (keine kritischen Treffer); leicht < 150 HP (Hinweis), mittel < 90 HP (Humpeln, HUD), bewusstlos statt Tod: liegt 15 min mit Timer im HUD, Eingaben gesperrt, Statebag `downed`; Verband +25, Erste-Hilfe-Kit +60 bzw. am Bewusstlosen +10 min (E „Erste Hilfe leisten“); Koma → Pillbox-Bett, Bargeld weg, 500 $ Krankenhaus (auch ins Minus), 5 min Ruhe; Team-Heilen belebt wieder; LSMD-Wiederbelebung in Phase 8 |
| 6.9 | Fitness und Promille | ✅ | Muscle Sands: 4 Stationen (E, 30 s Einheit, +1 %, 2 min Pause je Station), Energydrink +2 %, −1 % je Tag ohne Training; bis 8 % schneller und mehr Ausdauer; Promille: Bier +0,2, Schnaps +0,5, −0,1 je 10 min; ab 0,5 ‰ Torkeln, Kameraeffekt, Fahrzeug zieht, HUD-Hinweis; Atemtest kommt mit LSPD (Phase 8) |

## Phase 7 · Handy und Funk

| Nr. | Punkt | Status | Details |
| --- | --- | --- | --- |
| 7.1 | Handy-Item, Nummer, Grundgerüst der Oberfläche | ✅ | Handy (300 $, Elektronikladen) als Item; F1 öffnet nur, wenn es im eigenen Inventar liegt (Beschlagnahme = Sperre); vierstellige Nummer je Charakter (zufällig bei Erstauswahl, Wunschnummer nur per Ticket: `/nummer <ID> <4-stellig>`); Gerät unten rechts in iPhone-Optik; ohne Mauszeiger läuft das Spiel normal weiter (laufen, F1 weglegen – auch im Gespräch), **Alt** schaltet den Zeiger ein/aus, mit Zeiger kann man weiterlaufen, nur Umschauen geht nicht; bei Koma geht das Handy verloren; Flugmodus macht unerreichbar |
| 7.2 | Kontakte und Anrufe | ✅ | Kontakte anlegen/umbenennen/Favorit/löschen, Nummern tauschen über das X-Rad („Nummer tauschen“, ≤ 3 m); Wähltastatur; Anrufe klingeln 20 s (Ton, Handy öffnet sich), annehmen/auflegen, Gespräch über SaltyChat `EstablishCall`; Anrufliste in `phone_calls` |
| 7.3 | Nachrichten (SMS, Standort) | ✅ | Unterhaltungen je Nummer, ungelesen als Badge auf der App, SMS-Ton und Hinweis; Standort senden → Empfänger setzt Wegpunkt; Gruppen (bis 8) folgen mit dem Fraktionsteil |
| 7.4 | Bank-App | ✅ | Kontostand und letzte Buchungen, Überweisung an Nummer (Journal `ueberweisung`), Rechnung stellen/bezahlen (`invoices`) |
| 7.5 | Fahrzeuge-App | ✅ | Eigene Fahrzeuge mit Zustand, Garage, Tank, Kilometer; „Orten“ setzt Wegpunkt auf das ausgeparkte Fahrzeug; Schlüssel mit Nummer teilen |
| 7.6 | Einstellungen | ✅ | Klingelton (3), Flugmodus, Bedürfnisse als Zahl an/aus, HUD-Größe 90/100/110 % – lokal gespeichert, wirkt sofort |
| 7.7 | Funkgerät und Funk-App, Funkliste im HUD | ✅ | Funkgerät (250 $) schaltet die Funk-App frei; Frequenzen 1–999, 1–10 nur Fraktionen; Sprechen über SaltyChats eigene Funk-Taste; Teilnehmerliste im Handy und im HUD, Sprecher leuchten (`SaltyChat_RadioTrafficStateChanged` → Statebag `radioTalking`) |
| 7.8 | Notruf, Fraktion, Firma, Kamera, Feed | ⬜ | mit den jeweiligen Phasen |

## Phase 8 · Jobs, Lohn, Steuern

| Nr. | Punkt | Status | Details |
| --- | --- | --- | --- |
| 8.1 | Jobcenter und Job-Grundgerüst (Anmelden, Firmenfahrzeug, Lohn) | 🔧 | Jobcenter (Innenstadt, E) und Ansprechpartner je Hof (E, NPC-Aufgabe „Job-Ansprechpartner“); nur ein Job aktiv; Firmenfahrzeug am Hof (Kennzeichen JOB nnn, Schlüssel nur für den Arbeiter, weg bei Feierabend, zerstört = nur Lohn des Auftrags weg); Lohn je Auftrag aus dem NPC-Topf **aufs Konto**, 8 % Einkommensteuer in den Staatshaushalt; Obergrenze je Stunde als gleitendes Fenster → Schicht endet automatisch mit Hinweis; Routenpunkte sind Orte (Arten trash, busstop, address, tree, ore) und per Orte-Creator verschiebbar – Container, Haltestellen und Bäume springen im Spiel auf das nächste echte Objekt (Mülltonne, Haltestellenschild, Baum; Haltestellen notfalls auf die Straße); Tabellen `job_sessions`, `job_pay` (Migration 021); HUD zeigt Job und Station, Blip mit Route |
| 8.2 | Müllabfuhr | 🔧 | Müllhof La Puerta, Müllwagen; 8 Container je Route: am markierten Container E „Müllsack holen“ (4 s), Sack zum Müllwagen tragen und E „einwerfen“, dann weiter; zurück zum Hof → 180 $; **Führerschein C** |
| 8.3 | Lieferfahrer | 🔧 | Depot Cypress Flats, Transporter; 3–5 Läden im Umkreis von 3 km (plus Adressen aus dem Creator) (E „Paket abgeben“), zurück → 150/205/260 $; Führerschein B |
| 8.4 | Busfahrer | 🔧 | Busdepot, Bus; 10 Haltestellen in fester Reihenfolge, Halt 4 s mit ein-/aussteigenden NPC-Fahrgästen, zurück → 300 $; Führerschein C |
| 8.5 | Taxi | 🔧 | Downtown Cab Co., Taxi; Taxameter 25 $ + 1,80 $/100 m; NPC-Fahrgäste über F4 → „Fahrgast suchen“ (Abholung ≥ 300 m, Ziel aus Läden/Adressen); Spieler rufen über F4 → „Taxi rufen“ (Fahrer bekommen Wegpunkt), Fahrpreis geht beim Aussteigen automatisch vom Fahrgast an den Fahrer (Steuer an den Staat); Führerschein B |
| 8.6 | Holzfäller | 🔧 | Sägewerk Paleto, Pickup; **Axt aus dem Baumarkt (150 $)** nötig; Baum fällen (8 s, Axt-Animation am echten Baum), Stamm tragen und aufladen (×4), am Sägewerk abliefern → 220 $ |
| 8.7 | Bergbau | 🔧 | Mine Davis Quartz, zu Fuß; **Spitzhacke (150 $)** nötig; Erz abbauen (8 s, Spitzhacken-Animation, Item „Erz“ 2 kg), beim Händler verkaufen → 240 $ je 5 Erz (anteilig) |
| 8.8 | Payday, Einkommensteuer, Staatshaushalt | 🔧 | Fraktionsgehalt je volle Stunde (linear Rang 1–12 aus `Salaries`, bis Phase 9 zählt Spielzeit als Dienst) aus dem Staatshaushalt, 8 % Steuer; Kürzung anteilig, wenn die Reserve unter 2 Wochen Gehälter fällt, nie nachgedruckt; `payday_log`; Team-Menü → Welt → Staatshaushalt (Stand, Spielerkonten, Reserve, Buchungen der Woche je Grund) |
| 8.9 | Kaufzeiten-Simulation in der CI | 🔧 | `tools/ci/sim_economy.lua` (lua5.4 in der CI): rechnet aus Config-Werten die Stunden bis Auto D, Wohnung, Haus, Sportwagen A; Auto und Sportwagen sind Pflicht (±15 %), Wohnung/Haus bis Phase 10 nur Hinweis – mit den Konzeptwerten liegen sie weit außerhalb (siehe Entscheidungen 08.11.) |

## Phase 9 · Fraktionen

Vorgehen (Betreiber 08.11.): erst die gemeinsame Fraktionsbasis (9.1–9.3), danach jede Fraktion einzeln mit eigener Erklärung und Entscheidungen.

| Nr. | Punkt | Status | Details |
| --- | --- | --- | --- |
| 9.1 | Fraktionsmodul (Mitglieder, Ränge, Rechte, Kasse, Lager, Protokoll) | 🔧 | Staatsfraktionen fest (LSPD 20, LSMD offen, DMV 10, Regierung nur Team, DOJ 15; Funk 1–5, Notrufkanal 10 für LSPD+LSMD), kriminelle Fraktionen legt das Team an (Funk ab 6); Ränge 1–12 mit Standardrechten aus Konzept 2.1 (Flags: Funk hören/sprechen, Lager sehen/entnehmen/einlagern, Fahrzeuge Klasse 1/alle, Einladen, Kasse sehen/auszahlen, Ränge 1–8, Entlassen, Einstellungen, Leader), Rangnamen frei; Kasse = Konto `faction` im Journal, Tageslimits (Entnahme 10–80 kg, Auszahlung 5.000 $ für Rang 9–10); Lager 500 kg mit Rechten je Richtung; Beitritt prüft Cap, Gang-Level (4 Hangaround, 9 Mitglied, max. 2 Hangarounds), Sperre 5 Tage (kriminell → Staat 3); Protokoll `faction_log`; Team-Menü → Fraktionen (anlegen, Leader, Mitglied, entfernen, auflösen → Kasse an den Staat); Tabellen Migration 022 |
| 9.2 | Dienst, Dienstkleidung, Fraktionsfahrzeuge | 🔧 | Stempeluhr (Ort `faction_duty_<id>`, E oder F6) → Statebag `duty`, Gehalt (Payday) läuft nur im Dienst; Umkleide (`faction_wardrobe_<id>`): Dienstkleidung je Fraktion (Leitung speichert die aktuelle Kleidung mit Mindestrang), Zivilkleidung wird gemerkt und zurückgeholt; Garage (`faction_garage_<id>` mit Ausfahrt): Fahrzeugliste je Fraktion (Leitung trägt Modell/Bezeichnung/Mindestrang ein), Kennzeichen `LSPD 123`, Schlüssel für alle Mitglieder (Staat: nur im Dienst), Klasse 1 ab Rang 3, alle ab Rang 6; Orte setzt das Team mit dem Orte-Creator |
| 9.3 | Fraktionsmenü (F6) vollständig | 🔧 | Dienst, Mitglieder (befördern/degradieren/Rang eingeben, entlassen, Leitung übergeben), Kasse (einzahlen, auszahlen, Journal), Lager, Fahrzeuge, Umkleide, Ränge und Rechte (Rangname, Rechte je Rang an/aus), Protokoll, Austreten; Einladen über das X-Rad („In Fraktion einladen“, Antwortmenü, Beitritt als Rang 1); HUD zeigt Fraktion, Rangname und „im Dienst“ |
| 9.4 | LSPD: MDT | 🔧 | Wache Mission Row (Stempeluhr, Umkleide, Lager, Ausrüstung, Asservatenkammer, Garage, 3 Zellen, Entlassung – alle Orte verschiebbar); MDT überall im Dienst (F6 → MDT, `/mdt`, X-Rad): Personensuche nach Name/Handynummer, Akte (Führerscheine, Punkte, Fahrzeuge, Einträge, Haftbefehle), Kennzeichenabfrage (Halter, Zulassung, Verwahrhof, Fahndung), Einträge anlegen, Haftbefehl/Fahrzeugfahndung setzen und aufheben (ab Rang 5), Berichte; jede Abfrage in `mdt_queries`; Tabellen Migration 023 |
| 9.5 | LSPD: Dispatch und Notrufe | 🔧 | Handy-App Notruf: 110 (LSPD) / 112 (LSMD) mit Text und Standort, 30 s Sperre; Diensthabende bekommen Ton, Hinweis mit Straße und blinkenden Blip; F6 → Einsätze: Liste, übernehmen (Wegpunkt, Anrufer wird informiert), abschließen, eigener Status (Frei/Im Einsatz/Pause), Einheiten im Dienst; automatische Meldungen: Schüsse (je Spieler alle 90 s, Ort bis 60 m unscharf, nicht bei Taser/Schalldämpfer/Polizei im Dienst) und Blitzer ab 40 km/h drüber |
| 9.6 | LSPD: Kontrolle, Beschlagnahme, Verhaftung | 🔧 | X-Rad → „Polizei“ am Spieler: Handschellen **jederzeit** im Nahbereich (Waffe wird weggesteckt, Tasten gesperrt), Abführen, ins Fahrzeug setzen/herausholen, Ausweis und Führerschein (verlangen bzw. bei Gefesselten/Bewusstlosen abnehmen), Atemtest, Durchsuchen (nur gefesselt/bewusstlos; Abgenommenes landet beim Beamten → Asservatenkammer, Entnahme ab Rang 9), Geldstrafe bis 10.000 $ ab Rang 3 (vom Konto an den Staat, auch ins Minus, Akteneintrag), Festnehmen in der Wache bis 60 min ab Rang 3 (Zelle, Timer im HUD, läuft nur online, vorzeitige Entlassung über F6 → Insassen); am Fahrzeug: Kennzeichen abfragen, Beschlagnahmen (Verwahrhof, 750 $ Auslösung); Ausrüstungs-Kaufpunkt (Taschenlampe, Schlagstock, Taser, Dienstpistole, Karabiner ab Rang 6, Munition, Weste – bleibt beim Beamten); dazu Waffen-Grundlage: Waffen-Items ziehen/wegstecken, Munition aus Items, Weste |
| 9.7 | LSMD: Verletzungssystem, Krankenhaus, Rechnungen | ⬜ | |
| 9.8 | DMV im Fraktionsbetrieb | ⬜ | |
| 9.9 | Regierung: Rathaus, Bürgerbüro, Lizenzamt | ⬜ | |
| 9.10 | DOJ: Gericht, Kaution, Verfahren | ⬜ | |
| 9.11 | Streetgang: Ganghaus, Gebiete, Gangwar | ⬜ | |

## Phase 10 · Immobilien und Firmen

| Nr. | Punkt | Status |
| --- | --- | --- |
| 10.1 | Immobilien: Typen, Kauf/Miete, Schlüssel, Lager | ⬜ |
| 10.2 | Sozialwohnung und Mietrückstand | ⬜ |
| 10.3 | Garagen an Immobilien | ⬜ |
| 10.4 | Möbelhaus | ⬜ |
| 10.5 | Firma Burger Shot | ⬜ |

## Phase 11 · Verbrechen und Justiz

| Nr. | Punkt | Status |
| --- | --- | --- |
| 11.1 | Drogen: Anbau, Herstellung, Verkauf, Wirkung | ⬜ |
| 11.2 | Waffen: Waffenschein, Kauf, Schwarzmarkt, Munition | ⬜ |
| 11.3 | Hehler und Schwarzgeldwäsche | ⬜ |
| 11.4 | Raub: Läden, Juwelier, Bank, Spieler | ⬜ |
| 11.5 | Strafkatalog, Geldstrafen, Punkte | ⬜ |
| 11.6 | Haft und Gefängnis | ⬜ |
| 11.7 | Koma, Tod, Permatod | ⬜ |

## Phase 12 · Team-Werkzeuge und Betrieb

| Nr. | Punkt | Status |
| --- | --- | --- |
| 12.1 | Team-Menü (F9) vollständig (Erweiterungen aus Phase 5) | ⬜ |
| 12.2 | Tickets und Spieler-Akte vollständig | ⬜ |
| 12.3 | Anti-Cheat vollständig | ⬜ |
| 12.4 | Backups, Monitoring, Neustarts, Testserver | ⬜ |
| 12.5 | Wochenberichte (Geldmenge, Aktivität) | ⬜ |

## Phase 13 · Beta und Start

| Nr. | Punkt | Status |
| --- | --- | --- |
| 13.1 | Geschlossene Beta (10 Slots, 2 Wochen) | ⬜ |
| 13.2 | Balancing über Config | ⬜ |
| 13.3 | Regelwerk und Einstiegstexte | ⬜ |
| 13.4 | Start | ⬜ |
