// Whitelist per Reaktion auf die Willkommensnachricht (Konzept 1, Abschnitt 3).
// Ablauf: Reaktion -> Sperre? -> Name gegen Blockliste -> Rolle Whitelist + Zeile in `whitelist`.
import { query, ENVS } from './db.js';

async function queryAll(sql, params) {
  for (const env of ENVS) await query(sql, params, env.key).catch((e) => console.error(`[bot] Whitelist (${env.label})`, e.message));
}
import { config } from './config.js';

async function isBanned(discordId) {
  const rows = await query(
    'SELECT id FROM bans WHERE discord_id = ? AND lifted_at IS NULL AND (until_at IS NULL OR until_at > NOW()) LIMIT 1',
    [discordId],
  );
  return rows.length > 0;
}

async function nameBlocked(name) {
  const rows = await query('SELECT pattern FROM name_blocklist');
  const lower = name.toLowerCase();
  return rows.some((r) => lower.includes(String(r.pattern).toLowerCase()));
}

export async function handleReaction(reaction, user, client) {
  if (user.bot) return;
  if (reaction.partial) {
    try { await reaction.fetch(); } catch { return; }
  }
  const { channelId, messageId, emoji } = config.welcome;
  if (reaction.message.channelId !== channelId || reaction.message.id !== messageId) return;
  if (reaction.emoji.name !== emoji) return;

  const guild = await client.guilds.fetch(config.guildId);
  const member = await guild.members.fetch(user.id).catch(() => null);
  if (!member) return;

  const displayName = member.displayName || user.username;

  if (await isBanned(user.id)) {
    await reaction.users.remove(user.id).catch(() => {});
    await user.send('Dein Zugang zu TacoV ist gesperrt.').catch(() => {});
    return;
  }
  if (await nameBlocked(displayName)) {
    await reaction.users.remove(user.id).catch(() => {});
    await user.send('Dein Discord-Name ist auf TacoV nicht erlaubt. Bitte ändere ihn und reagiere erneut.').catch(() => {});
    return;
  }

  await queryAll(
    'INSERT INTO whitelist (discord_id, discord_name, added_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE discord_name = VALUES(discord_name)',
    [user.id, displayName.slice(0, 64), 'bot'],
  );
  await member.roles.add(config.roles.whitelist).catch((e) => console.error('[bot] Rolle Whitelist', e.message));
  await user.send('Willkommen bei TacoV! Du bist freigeschaltet und kannst den Server betreten.').catch(() => {});
  await queryAll('INSERT INTO logs (category, discord_id, message) VALUES (?, ?, ?)', ['connect', user.id, `Whitelist per Reaktion: ${displayName}`]);
}

export async function handleReactionRemoved(reaction, user) {
  if (user.bot) return;
  if (reaction.partial) {
    try { await reaction.fetch(); } catch { return; }
  }
  const { channelId, messageId } = config.welcome;
  if (reaction.message.channelId !== channelId || reaction.message.id !== messageId) return;
  // Reaktion weg = Whitelist bleibt; Entzug nur durch das Team (/sperre im Spiel oder manuell in der DB).
}

// Wer die Rolle Whitelist manuell bekommt, wird ebenfalls eingetragen (Team kann so freischalten).
export async function handleMemberUpdate(oldMember, newMember) {
  const had = oldMember.roles.cache.has(config.roles.whitelist);
  const has = newMember.roles.cache.has(config.roles.whitelist);
  if (!had && has) {
    await query(
      'INSERT INTO whitelist (discord_id, discord_name, added_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE discord_name = VALUES(discord_name)',
      [newMember.id, newMember.displayName.slice(0, 64), 'role'],
    );
  }
  if (had && !has) {
    await queryAll('DELETE FROM whitelist WHERE discord_id = ?', [newMember.id]);
    await queryAll('INSERT INTO logs (category, discord_id, message) VALUES (?, ?, ?)', ['admin', newMember.id, 'Whitelist-Rolle entfernt']);
  }
}
