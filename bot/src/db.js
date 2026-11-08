// Datenbankzugriff. `live` ist die Datenbank des Liveservers; optional hängt der Bot zusätzlich an der Testserver-Datenbank
// (DB_TEST_NAME in .env) und spiegelt deren Logs, Tickets, Anti-Cheat-Meldungen und Status – gekennzeichnet als Testserver.
import mysql from 'mysql2/promise';
import { config } from './config.js';

function makePool(db) {
  return mysql.createPool({ ...db, waitForConnections: true, connectionLimit: 4, charset: 'utf8mb4' });
}

export const pool = makePool(config.db);
export const testPool = config.dbTest ? makePool(config.dbTest) : null;

/** Umgebungen, über die Module laufen: key, Anzeigename, Kennzeichnung für Nachrichten */
export const ENVS = [
  { key: 'live', label: 'Liveserver', tag: '' },
  ...(testPool ? [{ key: 'test', label: 'Testserver', tag: '🧪 Testserver · ' }] : []),
];

export async function query(sql, params = [], env = 'live') {
  const p = env === 'test' ? testPool : pool;
  if (!p) throw new Error(`Datenbank ${env} nicht konfiguriert`);
  const [rows] = await p.execute(sql, params);
  return rows;
}

const tableCache = {};
/** Gibt es die Tabelle in dieser Umgebung? (gecacht, alle 5 min neu geprüft) – damit der Bot vor einer Migration nicht spammt */
export async function hasTable(name, env = 'live') {
  const k = `${env}:${name}`;
  const c = tableCache[k];
  if (c && Date.now() - c.at < 300000) return c.ok;
  let ok = false;
  try {
    const rows = await query('SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ? LIMIT 1', [name], env);
    ok = rows.length > 0;
  } catch { ok = false; }
  tableCache[k] = { ok, at: Date.now() };
  return ok;
}
