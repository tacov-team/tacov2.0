// Spiegelt neue Zeilen aus der Tabelle `logs` in die Discord-Log-Kanäle.
import { query, ENVS } from './db.js';
import { config } from './config.js';

const lastId = {};

async function init() {
  for (const env of ENVS) {
    const rows = await query('SELECT COALESCE(MAX(id), 0) AS id FROM logs', [], env.key);
    lastId[env.key] = Number(rows[0].id);
  }
}

function fmt(row, env) {
  const when = new Date(row.at).toLocaleTimeString('de-DE');
  const who = row.character_id ? `#${row.character_id}` : row.discord_id ? `<@${row.discord_id}>` : '—';
  return `${env.tag}\`${when}\` ${who} · ${row.message}`;
}

export async function startLogMirror(client) {
  await init();
  const channels = {};
  for (const [cat, id] of Object.entries(config.logChannels)) {
    if (!id) continue;
    channels[cat] = await client.channels.fetch(id).catch(() => null);
    if (!channels[cat]) console.warn(`[bot] Log-Kanal ${cat} (${id}) nicht gefunden`);
  }

  setInterval(async () => {
    for (const env of ENVS) {
      try {
        const rows = await query('SELECT id, at, category, character_id, discord_id, message FROM logs WHERE id > ? ORDER BY id LIMIT 50', [lastId[env.key]], env.key);
        for (const row of rows) {
          lastId[env.key] = Number(row.id);
          const ch = channels[row.category];
          if (ch) await ch.send({ content: fmt(row, env), allowedMentions: { parse: [] } }).catch(() => {});
        }
      } catch (e) {
        console.error(`[bot] Log-Spiegel (${env.label})`, e.message);
      }
    }
  }, config.logPollSeconds * 1000);
}
