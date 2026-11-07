// Zweites Embed im Kanal „Server Status“: TeamSpeak (Punkt 1.10). Fragt den ServerQuery auf dem VPS ab
// (TS_QUERY_PASS aus .env; setup-teamspeak.sh trägt ihn ein). Nachricht wird einmal gepostet und danach bearbeitet.
import net from 'node:net';
import { EmbedBuilder } from 'discord.js';
import { query } from './db.js';
import { config } from './config.js';

function unescapeTs(s) {
  return s.replace(/\\s/g, ' ').replace(/\\p/g, '|').replace(/\\\//g, '/').replace(/\\\\/g, '\\');
}

/** Kurze ServerQuery-Sitzung: login, use, serverinfo, clientlist → Objekt oder null */
function queryTeamspeak() {
  return new Promise((resolve) => {
    const { host, port, pass } = config.teamspeak;
    const sock = net.createConnection({ host, port }, () => {
      const cmds = [`login serveradmin ${pass.replace(/ /g, '\\s')}`, 'use sid=1', 'serverinfo', 'clientlist', 'quit'];
      sock.write(cmds.join('\n') + '\n');
    });
    let buf = '';
    const done = (v) => { sock.destroy(); resolve(v); };
    sock.setTimeout(5000, () => done(null));
    sock.on('error', () => done(null));
    sock.on('data', (d) => { buf += d.toString('utf8'); });
    sock.on('close', () => {
      const text = buf.replace(/\r/g, '');
      if (!/virtualserver_name=/.test(text)) return resolve(null);
      const get = (k) => { const m = text.match(new RegExp(`${k}=([^ \\n]*)`)); return m ? unescapeTs(m[1]) : null; };
      const clients = (text.match(/clid=\d+ cid=\d+[^\n]*/g) || []).filter((c) => /client_type=0/.test(c));
      resolve({
        name: get('virtualserver_name'),
        online: clients.length,
        max: Number(get('virtualserver_maxclients') || 0),
        uptime: Number(get('virtualserver_uptime') || 0),
        clients: clients.map((c) => { const m = c.match(/client_nickname=([^ ]*)/); return m ? unescapeTs(m[1]) : '?'; }),
      });
    });
  });
}

function fmtDuration(seconds) {
  const d = Math.floor(seconds / 86400), h = Math.floor((seconds % 86400) / 3600), m = Math.floor((seconds % 3600) / 60);
  return d > 0 ? `${d} d ${h} h` : h > 0 ? `${h} h ${m} min` : `${m} min`;
}

function buildEmbed(info) {
  const embed = new EmbedBuilder().setTimestamp(new Date()).setFooter({ text: 'TeamSpeak 3 + SaltyChat · aktualisiert alle 30 Sekunden' });
  if (!info) {
    return embed.setTitle('🔴 TeamSpeak ist offline').setColor(0xf05252).setDescription(config.teamspeak.address ? `Adresse: \`${config.teamspeak.address}\`` : null);
  }
  embed.setTitle('🟢 TeamSpeak ist online').setColor(0x8b5cf6).addFields(
    { name: 'Adresse', value: config.teamspeak.address ? `\`${config.teamspeak.address}\`` : '–', inline: true },
    { name: 'Verbunden', value: `${info.online} / ${info.max}`, inline: true },
    { name: 'Läuft seit', value: fmtDuration(info.uptime), inline: true },
  );
  if (info.clients.length > 0) {
    embed.addFields({ name: 'Online', value: info.clients.slice(0, 25).join(', ').slice(0, 1000) });
  }
  return embed;
}

export async function startTeamspeakStatus(client) {
  if (!config.statusChannelId || !config.teamspeak.pass) {
    console.warn('[bot] TeamSpeak-Embed aus (statusChannelId oder TS_QUERY_PASS fehlt)');
    return;
  }
  const channel = await client.channels.fetch(config.statusChannelId).catch(() => null);
  if (!channel) return;
  let message = null;
  const rows = await query('SELECT v FROM bot_state WHERE k = ?', ['ts_status_message_id']);
  if (rows[0]?.v) message = await channel.messages.fetch(rows[0].v).catch(() => null);
  let lastKey = '';
  const tick = async () => {
    try {
      const embed = buildEmbed(await queryTeamspeak());
      const key = JSON.stringify(embed.data.fields || '') + (embed.data.title || '');
      if (!message) {
        message = await channel.send({ embeds: [embed] });
        await query('INSERT INTO bot_state (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', ['ts_status_message_id', message.id]);
        lastKey = key;
      } else if (key !== lastKey) {
        await message.edit({ embeds: [embed] });
        lastKey = key;
      }
    } catch (e) {
      console.error('[bot] TeamSpeak-Status', e.message);
    }
  };
  await tick();
  setInterval(tick, 30000);
}
