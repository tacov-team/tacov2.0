// Anti-Cheat-Meldungen (Punkt 5.16): neue Zeilen aus `ac_reports` als Embed in den AC-Kanal, AC-Team-Rolle wird erwähnt.
import { EmbedBuilder } from 'discord.js';
import { query, ENVS } from './db.js';
import { config } from './config.js';

const POLL_MS = 10000;
const COLORS = { none: 0x8b5cf6, kick: 0xf59e0b, ban: 0xf05252 };
const LABELS = { none: 'Hinweis', kick: 'Sicherheits-Kick', ban: 'Sicherheitssperre' };

async function tickEnv(client, env) {
  const rows = await query('SELECT * FROM ac_reports WHERE posted_discord = 0 ORDER BY id LIMIT 20', [], env.key);
  if (rows.length === 0) return;
  const ch = await client.channels.fetch(config.anticheat.channelId).catch(() => null);
  for (const r of rows) {
    if (ch) {
      const embed = new EmbedBuilder()
        .setTitle(`Anti-Cheat #${r.id} · ${r.kind}${env.key === 'test' ? ' · 🧪 Testserver' : ''}`)
        .setColor(COLORS[r.action] ?? COLORS.none)
        .addFields(
          { name: 'Spieler', value: `${r.player_name}\nDiscord <@${r.discord_id}> (${r.discord_id})`, inline: true },
          { name: 'Charakter', value: r.character_id ? `#${r.character_id}` : '–', inline: true },
          { name: 'Maßnahme', value: LABELS[r.action] ?? r.action, inline: true },
          { name: 'Details', value: r.details.slice(0, 1000) },
        )
        .setTimestamp(new Date(r.created_at));
      if (env.key === 'test') embed.setFooter({ text: 'Meldung vom Testserver (tacov2_test)' });
      const mention = config.anticheat.roleId ? `<@&${config.anticheat.roleId}>` : '';
      const content = `${env.tag}${mention}`.trim();
      await ch.send({ content: content || undefined, embeds: [embed], allowedMentions: { roles: config.anticheat.roleId ? [config.anticheat.roleId] : [] } })
        .catch((e) => console.error('[ac] senden', e.message));
    }
    await query('UPDATE ac_reports SET posted_discord = 1 WHERE id = ?', [r.id], env.key);
  }
}

async function tick(client) {
  for (const env of ENVS) await tickEnv(client, env).catch((e) => console.error(`[ac] (${env.label})`, e.message));
}

export async function startAnticheat(client) {
  if (!config.anticheat.channelId) { console.warn('[ac] anticheat.channelId fehlt in discord.json'); return; }
  const run = () => tick(client).catch((e) => console.error('[ac]', e.message));
  await run();
  setInterval(run, POLL_MS);
  console.log('[ac] Meldungen laufen');
}
