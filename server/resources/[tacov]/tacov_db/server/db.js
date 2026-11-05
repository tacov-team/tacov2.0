// TacoV Datenbank-Resource. Läuft in der Node-Laufzeit des FXServers und hält den Verbindungspool.
// Alle anderen Resources sprechen nur über die Exports (mit Rückruf); der Kern kapselt sie in TacoV.DB (Lua).
//
// Convar:  set tacov_db "mysql://nutzer:passwort@127.0.0.1:3306/tacov2"
// Exports: query, single, scalar, insert, update, transaction, ready  (alle: (sql, params, cb) bzw. (queries, cb))

// Treiber über den echten Resource-Pfad laden; FXServer löst node_modules sonst nicht zuverlässig auf
const path = require('path');
const resourcePath = GetResourcePath(GetCurrentResourceName());
let mysql;
try {
  mysql = require(path.join(resourcePath, 'node_modules', 'mysql2', 'promise'));
} catch (e) {
  console.log(`^1[tacov_db]^7 Treiber mysql2 fehlt: ${e.message}`);
  console.log(`^1[tacov_db]^7 Bitte ausführen: cd "${resourcePath}" && npm install`);
}

const NULL = '\u0000NULL'; // Lua kann kein nil in Listen übertragen; der Kern schickt diesen Platzhalter
const TAG = '^3[tacov_db]^7';

function parseUrl(url) {
  const m = /^mysql:\/\/([^:]+):([^@]*)@([^:/]+)(?::(\d+))?\/([^?]+)/.exec(url || '');
  if (!m) return null;
  return { user: decodeURIComponent(m[1]), password: decodeURIComponent(m[2]), host: m[3], port: Number(m[4] || 3306), database: m[5] };
}

const conf = parseUrl(GetConvar('tacov_db', ''));
if (!conf) {
  console.log(`^1[tacov_db]^7 Convar tacov_db fehlt oder ist ungültig (mysql://nutzer:passwort@host:port/datenbank)`);
}

const pool = conf && mysql && mysql.createPool({
  ...conf,
  waitForConnections: true,
  connectionLimit: 10,
  charset: 'utf8mb4',
  dateStrings: true,      // Datumswerte als Text, damit Lua sie direkt verwenden kann
  jsonStrings: true,      // JSON-Spalten als Text; der Kern dekodiert selbst
  supportBigNumbers: true,
  bigNumberStrings: false,
  namedPlaceholders: false,
});

let ready = false;

function fixParams(sql, params) {
  const list = Array.isArray(params) ? params.map((v) => (v === NULL || v === undefined ? null : v)) : [];
  const need = (sql.match(/\?/g) || []).length;
  while (list.length < need) list.push(null); // Lua verliert abschließende nil-Werte
  return list.slice(0, need);
}

async function run(conn, sql, params) {
  const p = fixParams(sql, params);
  // Ohne Parameter normales Query (DDL, SELECT 1), sonst Prepared Statement
  const [res] = p.length === 0 ? await conn.query(sql) : await conn.execute(sql, p);
  return res;
}

function wrap(fn) {
  return (...args) => {
    const cb = typeof args[args.length - 1] === 'function' ? args.pop() : null;
    fn(...args).then(
      (res) => cb && cb(res === undefined ? null : res, null),
      (err) => {
        console.log(`^1[tacov_db]^7 ${err.message}\n  ${String(args[0]).slice(0, 200)}`);
        if (cb) cb(null, err.message);
      },
    );
  };
}

const api = {
  async query(sql, params) { return await run(pool, sql, params); },
  async single(sql, params) { const r = await run(pool, sql, params); return Array.isArray(r) && r.length ? r[0] : null; },
  async scalar(sql, params) {
    const r = await run(pool, sql, params);
    if (!Array.isArray(r) || !r.length) return null;
    const row = r[0];
    return row[Object.keys(row)[0]];
  },
  async insert(sql, params) { const r = await run(pool, sql, params); return r.insertId ?? null; },
  async update(sql, params) { const r = await run(pool, sql, params); return r.affectedRows ?? 0; },
  async transaction(queries) {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      for (const q of queries) {
        const sql = Array.isArray(q) ? q[0] : q.query ?? q[1];
        const params = Array.isArray(q) ? q[1] : q.values ?? q[2];
        await run(conn, sql, params);
      }
      await conn.commit();
      return true;
    } catch (e) {
      await conn.rollback().catch(() => {});
      throw e;
    } finally {
      conn.release();
    }
  },
};

for (const [name, fn] of Object.entries(api)) exports(name, wrap(fn));
exports('ready', () => ready);

(async () => {
  if (!pool) return;
  for (let i = 1; ; i++) {
    try {
      await pool.query('SELECT 1');
      ready = true;
      console.log(`^2[tacov_db]^7 Verbunden mit ${conf.host}:${conf.port}/${conf.database}`);
      return;
    } catch (e) {
      if (i % 10 === 1) console.log(`${TAG} Warte auf Datenbank ... (${e.code || e.message})`);
      await new Promise((r) => setTimeout(r, 1000));
    }
  }
})();
