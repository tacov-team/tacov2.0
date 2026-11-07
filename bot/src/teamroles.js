// Team-Rollen (Punkt 0.11): Discord ist die Quelle. Die höchste Team-Rolle eines Mitglieds wird nach `players.role`
// gespiegelt; wer keine Team-Rolle (mehr) hat, wird wieder 'player'. Rechte gelten im Spiel nur im Admin-Dienst.
import { query } from './db.js';
import { config } from './config.js';

// Reihenfolge = Rang (höchste zuerst). Schlüssel = Rollenname im Spiel (config/permissions.lua)
export const TEAM_RANK = [
  'projektleitung', 'stv_projektleitung', 'manager', 'superadmin', 'administrator',
  'entwickler', 'gamedesigner', 'moderator', 'supporter', 'guide',
];

function roleOfMember(member) {
  for (const name of TEAM_RANK) {
    const id = config.teamRoles[name];
    if (id && member.roles.cache.has(id)) return name;
  }
  return 'player';
}

async function setRole(discordId, role, displayName) {
  const rows = await query('SELECT id, role FROM players WHERE discord_id = ?', [discordId]);
  if (rows.length === 0) {
    // Spieler war noch nie im Spiel: Zeile anlegen, damit die Rolle beim ersten Verbinden gilt
    if (role === 'player') return false;
    await query('INSERT INTO players (discord_id, role) VALUES (?, ?)', [discordId, role]);
  } else {
    if (rows[0].role === role) return false;
    await query('UPDATE players SET role = ? WHERE id = ?', [role, rows[0].id]);
  }
  await query('INSERT INTO logs (category, discord_id, message) VALUES (?, ?, ?)',
    ['admin', discordId, `Team-Rolle aus Discord: ${displayName} -> ${role}`]);
  return true;
}

export async function syncMember(member) {
  return setRole(member.id, roleOfMember(member), member.displayName || member.user?.username || member.id);
}

/** Beim Start: alle Mitglieder mit Team-Rolle abgleichen und Team-Rollen in der DB entfernen, die Discord nicht mehr hat. */
export async function syncAllTeamRoles(client) {
  const configured = Object.values(config.teamRoles).filter(Boolean);
  if (configured.length === 0) {
    console.warn('[bot] teamRoles in discord.json leer – Team-Rollen werden nicht gespiegelt');
    return;
  }
  const guild = await client.guilds.fetch(config.guildId);
  const members = await guild.members.fetch();
  const seen = new Set();
  let changed = 0;
  for (const member of members.values()) {
    if (member.user.bot) continue;
    const role = roleOfMember(member);
    if (role !== 'player') seen.add(member.id);
    if (await setRole(member.id, role, member.displayName)) changed++;
  }
  // DB-Teamrollen ohne Discord-Rolle zurücksetzen
  const rows = await query("SELECT discord_id FROM players WHERE role <> 'player'");
  for (const r of rows) {
    if (!seen.has(String(r.discord_id))) {
      await setRole(String(r.discord_id), 'player', String(r.discord_id));
      changed++;
    }
  }
  console.log(`[bot] Team-Rollen abgeglichen (${seen.size} Teammitglieder, ${changed} Änderungen)`);
}
