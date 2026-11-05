// Spiegelt neue Zeilen aus der Tabelle `logs` in die Discord-Log-Kanäle.
import { query } from './db.js';
import { config } from './config.js';

let lastId = 0;

async function init() {
  const rows = await query('SELECT COALESCE(MAX(id), 0) AS id FROM logs');
  lastId = Number(rows[0].id);
}

function fmt(row) {
  const when = new Date(row.at).toLocaleTimeString('de-DE');
  const who = row.character_id ? `#${row.character_id}` : row.discord_id ? `<@${row.discord_id}>` : '—';
  return `\`${when}\` ${who} · ${row.message}`;
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
    try {
      const rows = await query('SELECT id, at, category, character_id, discord_id, message FROM logs WHERE id > ? ORDER BY id LIMIT 50', [lastId]);
      for (const row of rows) {
        lastId = Number(row.id);
        const ch = channels[row.category];
        if (ch) await ch.send({ content: fmt(row), allowedMentions: { parse: [] } }).catch(() => {});
      }
    } catch (e) {
      console.error('[bot] Log-Spiegel', e.message);
    }
  }, config.logPollSeconds * 1000);
}
