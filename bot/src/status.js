// Status-Embed im Kanal „Server Status“ (Punkt 1.7) und Ansagen (Punkt 1.9).
// Der Spielserver schreibt alle 30 s `server_status`; ist die Zeile älter als 90 s, gilt der Server als offline.
// Die Embed-Nachricht wird einmal gepostet und danach nur noch bearbeitet (ID in `bot_state`).
import { EmbedBuilder } from 'discord.js';
import { query, ENVS } from './db.js';
import { config } from './config.js';

const STALE_SECONDS = 90;

async function stateGet(k) {
  const rows = await query('SELECT v FROM bot_state WHERE k = ?', [k]);
  return rows[0]?.v ?? null;
}
async function stateSet(k, v) {
  await query('INSERT INTO bot_state (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', [k, v]);
}

function fmtDuration(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  return h > 0 ? `${h} h ${m} min` : `${m} min`;
}

function fmtTime(d) {
  return new Date(d).toLocaleString('de-DE', { timeZone: 'Europe/Berlin', hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' });
}

function buildEmbed(row, testRow) {
  const now = Date.now();
  const updated = row ? new Date(row.updated_at).getTime() : 0;
  const online = row && now - updated < STALE_SECONDS * 1000;
  const embed = new EmbedBuilder()
    .setTitle(online ? '🟢 TacoV ist online' : '🔴 TacoV ist offline')
    .setColor(online ? 0x8b5cf6 : 0xf05252)
    .setTimestamp(new Date());
  if (online) {
    const uptime = row.started_at ? fmtDuration((now - new Date(row.started_at).getTime()) / 1000) : '–';
    embed.addFields(
      { name: 'Spieler', value: `${row.players} / ${row.slots}`, inline: true },
      { name: 'Nächster Neustart', value: row.next_restart_at ? `${fmtTime(row.next_restart_at)} Uhr` : '–', inline: true },
      { name: 'Läuft seit', value: uptime, inline: true },
      { name: 'Version', value: row.version ? `\`${row.version}\`` : '–', inline: true },
      { name: 'Neustarts', value: 'alle 6 Stunden (00, 06, 12, 18 Uhr)', inline: true },
    );
  } else {
    embed.setDescription(row?.updated_at ? `Zuletzt gesehen: ${fmtTime(row.updated_at)} Uhr` : 'Noch kein Lebenszeichen vom Spielserver.');
  }
  embed.setFooter({ text: 'Aktualisiert alle 30 Sekunden' });
  if (ENVS.some((e) => e.key === 'test')) {
    const tUpdated = testRow ? new Date(testRow.updated_at).getTime() : 0;
    const tOnline = testRow && now - tUpdated < STALE_SECONDS * 1000;
    embed.addFields({ name: '🧪 Testserver', value: tOnline ? `🟢 online · ${testRow.players} / ${testRow.slots} Spieler` : '🔴 offline', inline: false });
  }
  return embed;
}

export async function startStatus(client) {
  if (!config.statusChannelId) {
    console.warn('[bot] statusChannelId fehlt in discord.json – kein Status-Embed');
    return;
  }
  const channel = await client.channels.fetch(config.statusChannelId).catch(() => null);
  if (!channel) {
    console.warn('[bot] Status-Kanal nicht gefunden');
    return;
  }

  let message = null;
  const savedId = await stateGet('status_message_id');
  if (savedId) message = await channel.messages.fetch(savedId).catch(() => null);
  let lastKey = '';

  const tick = async () => {
    try {
      const rows = await query('SELECT * FROM server_status WHERE id = 1');
      const row = rows[0] || null;
      let testRow = null;
      if (ENVS.some((e) => e.key === 'test')) testRow = (await query('SELECT * FROM server_status WHERE id = 1', [], 'test').catch(() => []))[0] || null;
      const embed = buildEmbed(row, testRow);
      const key = JSON.stringify(embed.data.fields || embed.data.description || '') + (embed.data.title || '');
      if (!message) {
        message = await channel.send({ embeds: [embed] });
        await stateSet('status_message_id', message.id);
        lastKey = key;
      } else if (key !== lastKey) {
        await message.edit({ embeds: [embed] });
        lastKey = key;
      }

      // Ansagen (Neustart, Wartung) aus dem Spiel in den Status-Kanal
      for (const env of ENVS) {
        const pending = await query('SELECT id, kind, text FROM announcements WHERE posted_at IS NULL ORDER BY id LIMIT 10', [], env.key).catch(() => []);
        for (const a of pending) {
          const prefix = a.kind === 'restart' ? '🔄' : 'ℹ️';
          const content = `${prefix} ${env.tag}${a.text}`;
          if (a.kind === 'restart') {
            // Neustart-Hinweise: eine Nachricht je Umgebung, die bearbeitet wird (kein Dauerlauf im Kanal)
            const key = `restart_message_id_${env.key}`;
            const oldId = await stateGet(key);
            let edited = false;
            if (oldId) {
              const old = await channel.messages.fetch(oldId).catch(() => null);
              if (old) { edited = await old.edit(content).then(() => true).catch(() => false); }
            }
            if (!edited) {
              const m = await channel.send(content).catch(() => null);
              if (m) await stateSet(key, m.id);
            }
          } else {
            await channel.send(content).catch(() => {});
          }
          await query('UPDATE announcements SET posted_at = NOW() WHERE id = ?', [a.id], env.key);
        }
      }
    } catch (e) {
      console.error('[bot] Status', e.message);
    }
  };
  await tick();
  setInterval(tick, 30000);
}
