# Konzept 1 – Leitbild und Einstieg

Abgenommen am 2026-11-05.

## 1. Leitbild

TacoV ist ein deutscher Roleplay-Server auf FiveM für Spieler ab 18, bei dem die Geschichten der Spieler im Mittelpunkt stehen und das Spiel die Regeln so weit wie möglich selbst durchsetzt. Der Server startet klein mit 10 Slots und einem festen Kern an Staatsfraktionen und wächst in Seasons; was zum Start nicht gebraucht wird, wird nicht gebaut.

Grundsätze für jedes System:

- Regeln werden Mechanik: Was das Spiel erzwingen kann (Caps, Cooldowns, Zeitfenster, Rechte), steht im Code, nicht im Regelwerk.
- Jede Mechanik erzeugt Kontakt: Ein System, das ein Spieler allein durchspielen kann, wird so gebaut, dass es eine andere Gruppe braucht.
- Geld braucht Senken: Jede Einnahmequelle bekommt eine Ausgabeseite.
- Konsequenz ohne Frust: Haft, Koma und Verlust sind spürbar, aber mit Beschäftigung und Ausweg.
- Fraktionen tragen Geschichten: Werkzeuge für eigene Storylines statt vorgefertigter Szenarien.
- Der Server entscheidet: Geld, Items, Waffen und Rechte werden nie dem Client überlassen.

## 2. Start-Setup

| Punkt | Festlegung |
| --- | --- |
| Name | TacoV (endgültig) |
| Slots zum Start | 10; Erhöhung in Stufen (32, 64, 128), jede Stufe eine Entscheidung |
| Sprache | Deutsch im Spiel, im Discord und in allen Oberflächen; keine Rockstar-Markennamen in eigenen Texten |
| Setting | Los Santos und Blaine County, Gegenwart |
| Staatsfraktionen zum Start | LSPD, LSMD, DMV, Regierung (Gouverneur, Verwaltung, Standesamt), DOJ (Gericht, Staatsanwaltschaft, Anwälte) |
| Später möglich | FIB, Army, Werkstatt, Abschleppdienst, Medien, Guides |
| Kriminelle Fraktionen | Per Konzeptbewerbung; zum Start eine Streetgang (Abschnitt 2) |
| Spielstil | **Softcore/Midcore**: spürbare, aber nicht existenzbedrohende Konsequenzen – Permatod nur freiwillig, Koma mit Erinnerungsverlust statt Charakterverlust, Haft mit Beschäftigung, Neulingsschutz; Regeln so weit wie möglich im Code statt im Regelwerk |
| Schadensmodell | **Bodyshot**: keine Kopfschuss-Sofortkills, Kopftreffer zählen wie Körpertreffer (`SetPedSuffersCriticalHits` aus); Waffenschaden wird über die Config ausbalanciert |

Solange nur fünf Staatsfraktionen existieren: Abschleppen und Reparatur als Jobs mit Firmenoption, Einreise durch das Team, Ermittlungsarbeit beim LSPD.

## 3. Weg zum Server

Zugang komplett über Discord; kein Regeltest, kein Formular. Die Eignungsprüfung passiert im Spiel bei der Einreise.

1. Discord beitreten; der Bot zeigt in `#willkommen` Regeln, Altersgrenze 18+ und den Hinweis auf die IC-Einreise.
2. Reaktion auf die Nachricht = Bestätigung von Regeln und Alter.
3. Bot prüft: nicht auf der Sperrliste, Nutzername ohne verbotene Begriffe. Dann Rolle `Whitelist` und Eintrag in der Whitelist-Tabelle (Discord-ID).
4. Beim Verbinden prüft der Kern die Discord-ID gegen die Tabelle; ohne Eintrag Hinweis mit Discord-Link und Ablehnung.
5. Nach dem ersten Verbinden Rolle `Einwohner`; Sperren entfernen beide Rollen und sperren die Discord-ID.

Die Discord-ID ist der Kontoanker für Whitelist, Charaktere, Sperren und Tickets. Zweitkonten erkennt der Kern über gleiche FiveM-Lizenz und Hardware-Kennungen und meldet sie dem Team.

## 4. Einreise im Spiel

Jeder neue Charakter landet am Flughafen und durchläuft eine Einreise, die Roleplay-Einstieg und Eignungsprüfung zugleich ist. Nicht bestanden heißt Rückflug, kein Bann.

### Ablauf

1. Ladebildschirm, Charakterauswahl (ein Charakter je Spieler; Änderung 07.11.2026), Charaktereditor: Aussehen, Vor- und Nachname (Sperrliste, keine Doppelnamen), Geburtsdatum (mindestens 18), Herkunft.
2. Ankunftshalle; der Charakter hat nur Kleidung und Reisepass.
3. Einreisegespräch am Schalter mit einem Teammitglied mit der Rolle `Einreise` (Person, Grund der Einreise, Verhalten in zwei kurzen Situationen). Nur mit Teammitglied; ist niemand online, wartet der Charakter in der Ankunftshalle, das Handy zeigt die nächsten Einreisezeiten aus dem Discord.
4. Bestanden: Ausweis, 5.000 $ auf dem Konto, Handy, Schlüssel für eine Sozialwohnung (14 Tage kostenlos), Busticket, Stadtplan. Nicht bestanden: Grund, Rückflug, neuer Versuch nach 24 Stunden.
5. Vor dem Flughafen: Bushaltestelle, Taxistand, Hinweis auf DMV und Jobcenter.

### Neulingspfad

Aufgabenliste im Handy mit zehn Schritten (Wohnung betreten, Führerschein beim DMV, erster Job, erstes Fahrzeug ansehen, Bankkonto nutzen, Notruf kennenlernen, Kleidung kaufen, Essen und Trinken, eine Fraktion besuchen, Level 3 erreichen). Jeder Schritt gibt einen kleinen Bonus; freiwillig, nach Level 3 ausgeblendet.

## 5. Level, Noobschutz, Probezeit

Eine Stunde aktive Spielzeit = ein Levelpunkt; ab 20 Minuten ohne Bewegung oder Eingabe zählt die Zeit nicht (Änderung 07.11.2026).

| Level | Stunden | Bedeutung |
| --- | --- | --- |
| 1–3 | 0–3 | Noobschutz: kein Raub, keine Entführung, keine Geiselnahme; keine Waffen, keine Drogenverarbeitung, kein Beitritt zu kriminellen Fraktionen. Sichtbar im HUD und am Ausweis. |
| 4–8 | 3–8 | Probezeit: alle Systeme offen; Verstöße führen schneller zu Sperren; Fraktionsbeitritt nur als Hangaround. |
| 9–14 | 8–15 | Vollwertig: Fraktionen, Waffenschein, Firmengründung. |
| 15+ | 15+ | Leader-Positionen, Leasing, große Immobilien. |

Der Noobschutz endet vorzeitig, sobald der Spieler selbst eine Straftat begeht; der Kern hebt ihn auf und vermerkt es im Journal.

## 6. Team-Rollen und Rechte

Bestätigt am 2026-11-07 (Punkt 0.11). Die Rolle kommt aus Discord (der Bot spiegelt sie), Rechte gelten nur im **Admin-Dienst (Aduty, F9 oder `/aduty`)** – außerhalb ist ein Teammitglied ein normaler Spieler. Jede Team-Aktion wird geloggt (Kategorie `admin`).

| Stufe | Discord-Rolle | Darf (zusätzlich zur darunterliegenden Stufe) |
| --- | --- | --- |
| 1 | Supporter | Admin-Dienst, Tickets und Spieler-Akte lesen, zu Spielern teleportieren, unsichtbar beobachten, Einreise durchführen, Verwarnungen |
| 1 | Guide | nur: Admin-Dienst, Akte lesen, Teleport zu Spielern, Einreise |
| 2 | Moderator | Kicken, Sperren bis 7 Tage, Fahrzeuge löschen/zurücksetzen, Erstattungen bis 10.000 $, Noclip |
| 2 | Gamedesigner | nur: Akte lesen, Teleport, unsichtbar, Entwickler-Werkzeuge, Config lesen |
| 3 | Administrator | dauerhafte Sperren, Creator-Systeme (Türen, Aufzüge, Orte, Peds, Objekte, Zonen), Fahrzeuge spawnen, Welt-Steuerung (Wetter, Zeit, Ansagen), Rollen bis unter die eigene Stufe |
| 3 | Entwickler | wie Administrator plus Entwickler-Werkzeuge |
| 4 | Superadministrator | Items und Geld geben, Erstattungen bis 50.000 $, Fraktionsleitungen und Ränge |
| 5 | Manager | Config im Spiel ändern, Erstattungen über 50.000 $ (Vier-Augen-Prinzip), Datenbank-Werkzeuge |
| 6 | Stv. Projektleitung | alles |
| 7 | Projektleitung | alles |

## Config-Werte aus diesem Abschnitt

| Schlüssel | Wert |
| --- | --- |
| `server.slots` | 10 |
| `onboarding.start_cash` | 5000 |
| `onboarding.social_housing_days` | 14 |
| `onboarding.retry_hours` | 24 |
| `onboarding.requires_staff` | true |
| `level.hours_per_level` | 1 |
| `level.noob_protection_until` | 3 |
| `level.probation_until` | 8 |
| `level.second_character_at` | 15 |
| `whitelist.min_account_age_days` | 0 |
