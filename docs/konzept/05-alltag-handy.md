# Konzept 5 – Alltag und Handy

Abgenommen am 2026-11-05.

## 1. Inventar

Gewichtsbasiert, 30 kg Grundlast, Rucksack als Item (kein Modell) erhöht auf 45 kg. Voll heißt kein Aufnehmen; Rennen immer möglich. Alles Getragene ist raubbar und geht im Koma verloren.

| Punkt | Festlegung |
| --- | --- |
| Oberfläche | F2; links eigenes Inventar, rechts geöffneter Container; Mitte: gewähltes Item mit Anzahl, darunter Benutzen, Geben, Wegwerfen, Teilen; Ziehen zwischen Panels |
| Container | Kofferraum 20–200 kg je Klasse, Handschuhfach 5 kg, Immobilienlager nach Typ, Fraktionslager 500 kg (Rechte je Rang), Firmenlager 300 kg, Asservatenkammer |
| Geben | In 2 m, beide sehen die Übergabe |
| Wegwerfen | 15 min in der Welt sichtbar, dann weg; max. 10 je Charakter |
| Stapeln | Bis 50 (Munition 500); Qualitätsitems nur gleiche Qualität |
| Schnellzugriff | entfällt |
| Hotkeys | Handy F1, Inventar F2, Animationen F3, Aktionen F4, Fraktion F6, Team F9, Interaktion X, Hände hoch H, Befehlszeile T |

## 2. Bedürfnisse

| Wert | Verlauf | Folge | Verändern |
| --- | --- | --- | --- |
| Hunger | Leer nach 3 h (1 % je 108 s) | Bei 0: Lebenspunkte sinken 1 % je 30 s | Essen +25 %, Burger Shot +50 % |
| Durst | Leer nach 3 h | wie Hunger | Getränke +30 %, Wasser +20 % |
| Fitness | +1 % je Einheit an Sportgeräten, +2 % mit Energydrink; −1 % je Tag ohne Training; max. 100 % | Bei 100 % etwa 8 % schneller, längere Ausdauer | Gym, Sportgeräte, Energydrink |
| Promille | Bier +0,2, Schnaps +0,5; −0,1 je 10 min | Ab 0,5 schwankt das Fahrzeug; Atemtest LSPD (Trunkenheit am Steuer, 15 HE, 2 Punkte) | Alkohol |

Kein Stress, kein Schlaf. Offline keine Veränderung. Anzeige wird im Design festgelegt.

## 3. Handy

Bedienung: F1 holt das Handy raus, das Spiel läuft weiter (laufen, Kamera). Alt blendet den Mauszeiger ein – dann steht der Spieler und bedient die Apps; Alt erneut nimmt den Zeiger weg, F1 legt das Handy weg (auch während eines Gesprächs).

Item mit Nummer; Kontakte und Nachrichten hängen am Charakter. Zehn Apps:

| App | Funktion |
| --- | --- |
| Kontakte | Nummern, Anrufe (TeamSpeak-Privatkanal), Favoriten; Nummerntausch per Interaktionsmenü |
| Nachrichten | SMS, Standort teilen, Bilder; Gruppen bis 8 |
| Bank | Kontostand, Überweisung, Umsatz, Rechnungen; Business- und Fraktionsreiter bei Berechtigung |
| Notruf | LSPD, LSMD mit Standort; Notfallknopf (stiller Alarm) |
| Fraktion | Mitglieder online, Funkkanal, Dienst an/aus, Gebietsstatus |
| Fahrzeuge | Standort, Garage, Tank, Zustand, Orten (nur eigene), Schlüssel teilen |
| Firma | Mitarbeiter, Kasse, Bestellungen; Bestellen als Kunde |
| Kamera | Fotos, Galerie 50 Bilder |
| Nachrichten-Feed | Meldungen von Regierung und Team, Firmenwerbung |
| Einstellungen | Nummer, Klingelton, Flugmodus, Bedürfniswerte als Zahl, HUD-Skalierung |

Funk-App wird durch ein Funkgerät (Item) freigeschaltet. Ortung einer Nummer durch das LSPD nur mit DOJ-Anordnung. Tablet (MDT, Lagerverwaltung) in Phase 3.

## 4. Kleidung und Charakteroptik

Kleiderläden an allen 15 Standorten des Grundspiels; alles änderbar, was das Spiel am Charakter hergibt (alle Kategorien, Decals, Sticker, Westen, Rucksäcke, Masken, Accessoires). Friseur 7, Tattoo 6 Standorte (Grundspiel), Chirurg im Krankenhaus (5.000 $, einmal je 30 Tage).

- 10 gespeicherte Outfits je Charakter.
- Keine Namen über dem Kopf; Maskierte sind über den Ausweis nicht identifizierbar.
- Dienstkleidung: Staatsfraktionen stellen sie aus einem Fraktions-Katalog zusammen und speichern Outfits; verschwindet beim Dienstende. Gangkleidung in der Umkleide des Ganghauses.

## 5. Interaktion

| Punkt | Festlegung |
| --- | --- |
| Interaktionsmenü | X; Radialmenü, innen Allgemein, außen Kontext (Ziel in 2 m) |
| Animationsmenü | F3; 40 Animationen, Favoriten oben |
| Sprechweiten | 3 / 10 / 25 m, Umschalttaste, HUD-Anzeige |
| Funk | Funkgerät (250 $) schaltet Funk-App frei; Frequenzen 1–999; 1–10 sind Fraktionsfrequenzen; beschlagnahmtes Funkgerät abhörbar |
| Hände hoch | H |
| Befehlszeile | T; nur Commands, kein RP-Chat |
| Verletzungen | leicht (Kit oder LSMD hebt auf), mittel (nur LSMD; Kit stabilisiert), schwer (LSMD stabilisiert, Krankenhaus 5 min); nach 15 min ohne Versorgung Koma (Konzept 4) |

## 6. Läden und Orte

Orte des Grundspiels mit Standard-Koordinaten (orte.md); alle anderen sind Vorschläge und per Team-Befehl `/ort setzen <name>` verschiebbar (geloggt).

| Ort | Anzahl | Standort |
| --- | --- | --- |
| 24/7, LTD, Rob's Liquor | 9 + 5 + 5 | Grundspiel |
| Geldautomaten, Tankstellen | alle | Grundspiel |
| Bankfiliale | 2 | Pacific Standard, Fleeca Paleto |
| Baumarkt | 3 | Grundspiel |
| Apotheke | 2 | Vorschlag |
| Waffenladen | 11 | Grundspiel (Ammu-Nation) |
| Kleiderladen, Friseur, Tattoo | 15, 7, 6 | Grundspiel |
| Möbelhaus, Schlüsseldienst | 1, 1 | Vorschlag |
| Autohaus, LKW-Kaufhaus, Bootshaus, Flugzeughändler | je 1 | Vorschlag (Simeon, Hafen, Marina, Flugplatz Sandy Shores) |
| NPC-Werkstatt, Verwahrhof | 3, 1 | Grundspiel (LS Customs), Vorschlag |
| Jobcenter, Job-Ansprechpartner | 1 + 6 | Vorschlag |
| Burger Shot, Juwelier (Vangelico) | 1, 1 | Grundspiel |
| Gym, Sportgeräte, Angelladen, Muschelstrand | 1, 3, 1, 1 | Grundspiel (Muscle Sands), Vorschlag |
| Staatsgebäude | 5 + 2 | Mission Row, Pillbox, DMV (Vorschlag), Rathaus, Gericht; Pacific Standard, Bolingbroke |
| Schwarzmarkt, Hehler | 1 wandernd, 2 | Vorschlag |
| Flughafen | 1 | Grundspiel |

## 7. Freizeit zum Start

Angeln (Angel, Köder, Fischhändler), Muschelstrand (Muscheln sammeln, öffnen, 15 % Perle, Verkauf beim Juwelier), Gym und Sportgeräte (Fitness), Bars mit Alkohol, Events über den Feed. Casino und Rennen Season 2, Paintball und Arena Season 3, Jahrmarkt und Battle Royale Ideenliste.

## Config-Werte aus diesem Abschnitt

| Schlüssel | Wert |
| --- | --- |
| `inventory.base_weight` / `inventory.backpack_weight` | 30 / 45 |
| `inventory.full_blocks_pickup` / `inventory.full_blocks_sprint` | true / false |
| `inventory.drop_lifetime_min` / `inventory.drop_max_per_player` | 15 / 10 |
| `inventory.stack_max` / `inventory.stack_max_ammo` | 50 / 500 |
| `inventory.container.trunk` | 20–200 je Klasse |
| `inventory.container.glovebox` / `faction` / `business` | 5 / 500 / 300 |
| `keys` | phone F1, inventory F2, anims F3, faction F6, admin F9, interact X, handsup H, console T |
| `needs.hunger_minutes_to_empty` / `needs.thirst_minutes_to_empty` | 180 / 180 |
| `needs.starve_damage_percent_per_30s` | 1 |
| `needs.stress.enabled` | false |
| `fitness.gain_equipment` / `fitness.gain_energydrink` / `fitness.decay_per_day` / `fitness.max_speed_bonus_percent` | 1 / 2 / 1 / 8 |
| `alcohol.beer` / `alcohol.spirits` / `alcohol.decay_per_10min` / `alcohol.dui_threshold` | 0.2 / 0.5 / 0.1 / 0.5 |
| `phone.apps` | contacts, messages, bank, emergency, faction, vehicles, business, camera, feed, settings (+ radio bei Funkgerät) |
| `phone.gallery_max` / `phone.group_max` | 50 / 8 |
| `phone.locate_requires_doj` | true |
| `clothing.outfits_max` | 10 |
| `clothing.surgery_fee` / `clothing.surgery_cooldown_days` | 5000 / 30 |
| `radio.frequencies` / `radio.faction_frequencies` | 1–999 / 1–10 |
| `voice.ranges` | 3 / 10 / 25 |
| `chat.rp_enabled` | false |
| `names_above_head` | false |
| `leisure.pearl_chance_percent` | 15 |
