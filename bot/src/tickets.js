// Tickets (Punkt 5.15): je Ticket ein Textkanal in der Ticket-Kategorie. Neue Tickets und Spielnachrichten kommen aus der
// Datenbank (der Spielserver schreibt sie), Antworten aus dem Kanal gehen in `ticket_messages` (source = discord) und werden
// dem Spieler im Spiel gezeigt. `!schliessen` im Kanal schließt das Ticket.
import { ChannelType, EmbedBuilder, PermissionFlagsBits } from 'discord.js';
import { query } from './db.js';
import { config } from './config.js';

const POLL_MS = 10000;

function slug(s) {
  return String(s || 'spieler').toLowerCase().normalize('NFD').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 24) || 'spieler';
}

async function createChannel(client, guild, t) {
  const teamRoleIds = Object.values(config.teamRoles).filter(Boolean);
  const overwrites = [
    { id: guild.roles.everyone.id, deny: [PermissionFlagsBits.ViewChannel] },
    { id: client.user.id, allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ManageChannels] },
    ...teamRoleIds.map((id) => ({ id, allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ReadMessageHistory] })),
  ];
  // Spieler darf sein eigenes Ticket lesen und schreiben, wenn er auf dem Discord ist
  const member = await guild.members.fetch(t.discord_id).catch(() => null);
  if (member) overwrites.push({ id: member.id, allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ReadMessageHistory] });
  const ch = await guild.channels.create({
    name: `ticket-${t.id}-${slug(t.player_name)}`,
    type: ChannelType.GuildText,
    parent: config.ticketsCategoryId,
    topic: `Ticket #${t.id} · ${t.player_name} · Discord ${t.discord_id}`,
    permissionOverwrites: overwrites,
  });
  const embed = new EmbedBuilder()
    .setTitle(`Ticket #${t.id}`)
    .setColor(0x8b5cf6)
    .addFields(
      { name: 'Spieler', value: `${t.player_name}${member ? ` (<@${member.id}>)` : ''}`, inline: true },
      { name: 'Charakter', value: t.character_id ? `#${t.character_id}` : '–', inline: true },
      { name: 'Anliegen', value: t.subject.slice(0, 1000) },
    )
    .setFooter({ text: 'Antworten hier erreichen den Spieler im Spiel · !schliessen beendet das Ticket' })
    .setTimestamp(new Date(t.created_at));
  await ch.send({ embeds: [embed] });
  await query('UPDATE tickets SET discord_channel_id = ? WHERE id = ?', [ch.id, t.id]);
  return ch;
}

async function tick(client) {
  const guild = await client.guilds.fetch(config.guildId);
  // 1) Kanäle für neue Tickets
  const fresh = await query("SELECT * FROM tickets WHERE discord_channel_id IS NULL AND status <> 'closed' ORDER BY id LIMIT 5");
  for (const t of fresh) {
    try { await createChannel(client, guild, t); } catch (e) { console.error('[tickets] Kanal anlegen', t.id, e.message); }
  }
  // 2) Spiel-/Systemnachrichten in die Kanäle
  const msgs = await query(
    "SELECT m.id, m.ticket_id, m.source, m.author, m.text, t.discord_channel_id FROM ticket_messages m JOIN tickets t ON t.id = m.ticket_id " +
    "WHERE m.posted_discord = 0 AND m.source <> 'discord' AND t.discord_channel_id IS NOT NULL ORDER BY m.id LIMIT 30");
  for (const m of msgs) {
    const ch = await client.channels.fetch(m.discord_channel_id).catch(() => null);
    if (ch) {
      const prefix = m.source === 'system' ? 'ℹ️' : '🎮';
      await ch.send(`${prefix} **${m.author}:** ${m.text}`).catch((e) => console.error('[tickets] senden', e.message));
    }
    await query('UPDATE ticket_messages SET posted_discord = 1 WHERE id = ?', [m.id]);
  }
  // 3) Geschlossene Tickets: Kanal sperren und umbenennen
  const closed = await query("SELECT id, discord_channel_id, closed_by FROM tickets WHERE status = 'closed' AND discord_channel_id IS NOT NULL AND closed_at > NOW() - INTERVAL 2 MINUTE");
  for (const t of closed) {
    const ch = await client.channels.fetch(t.discord_channel_id).catch(() => null);
    if (ch && !ch.name.startsWith('geschlossen-')) {
      await ch.setName(`geschlossen-${t.id}`).catch(() => {});
      await ch.permissionOverwrites.edit(guild.roles.everyone.id, { SendMessages: false }).catch(() => {});
      await ch.send(`🔒 Ticket #${t.id} wurde geschlossen (${t.closed_by || 'Team'}).`).catch(() => {});
    }
  }
}

export async function startTickets(client) {
  if (!config.ticketsCategoryId) { console.warn('[tickets] ticketsCategoryId fehlt in discord.json – Tickets werden nicht gespiegelt'); return; }
  const run = () => tick(client).catch((e) => console.error('[tickets]', e.message));
  await run();
  setInterval(run, POLL_MS);
  console.log('[tickets] Spiegel läuft');
}

/** Nachrichten in Ticket-Kanälen: ins Spiel weiterreichen, !schliessen schließt */
export async function handleTicketMessage(message) {
  if (message.author.bot || !message.guild) return;
  const ch = message.channel;
  if (!ch || ch.parentId !== config.ticketsCategoryId) return;
  const m = /^(?:ticket|geschlossen)-(\d+)/.exec(ch.name);
  if (!m) return;
  const ticketId = Number(m[1]);
  const text = message.content.trim();
  if (!text) return;
  const author = message.member?.displayName || message.author.username;
  if (/^!(schliessen|schließen|close)$/i.test(text)) {
    await query("UPDATE tickets SET status = 'closed', closed_by = ?, closed_at = NOW() WHERE id = ? AND status <> 'closed'", [author, ticketId]);
    await query("INSERT INTO ticket_messages (ticket_id, source, author, text, posted_discord) VALUES (?, 'system', ?, ?, 1)", [ticketId, author, `${author} hat das Ticket in Discord geschlossen.`]);
    return;
  }
  const isTeam = Object.values(config.teamRoles).some((id) => id && message.member?.roles.cache.has(id));
  await query("INSERT INTO ticket_messages (ticket_id, source, author, text, posted_discord) VALUES (?, 'discord', ?, ?, 1)",
    [ticketId, isTeam ? `${author} (Team)` : author, text.slice(0, 1000)]);
  await message.react('✅').catch(() => {});
}
