# Modul: Datenbank (`tacov_db`)

Eigene Resource in JavaScript (läuft in der Node-Laufzeit des FXServers). Hält den Verbindungspool zu MariaDB und bietet Exports mit Rückruf. Einziger Fremdcode ist der Treiber `mysql2` (npm).

## Convar
`set tacov_db "mysql://nutzer:passwort@127.0.0.1:3306/tacov2"` in `server.cfg`.

## Exports
| Export | Rückgabe |
| --- | --- |
| `query(sql, params, cb)` | Zeilen (Liste) oder Ergebnisobjekt |
| `single(sql, params, cb)` | erste Zeile oder null |
| `scalar(sql, params, cb)` | erste Spalte der ersten Zeile |
| `insert(sql, params, cb)` | `insertId` |
| `update(sql, params, cb)` | `affectedRows` |
| `transaction([{sql, params}, …], cb)` | true; bei Fehler Rollback und Fehlertext |
| `ready()` | true, sobald die Verbindung steht |

`cb(ergebnis, fehler)`. Parameter sind `?`-Platzhalter; fehlende Werte am Ende werden mit NULL aufgefüllt, der Platzhalter `"\0NULL"` wird zu NULL (Lua kann kein nil in Listen übertragen).

## Nutzung aus Lua
Nie direkt: der Kern kapselt alles in `TacoV.DB.query/single/scalar/insert/update/transaction` (synchron per Promise). Andere Resources bekommen Datenbankzugriff nur über den Kern.

## Einrichten
`cd server/resources/[tacov]/tacov_db && npm install` (macht `tools/vps/setup.sh` und `deploy.sh` automatisch).
