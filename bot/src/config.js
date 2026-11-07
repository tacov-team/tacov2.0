import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

// Geheimnisse (.env) und Discord-IDs (discord.json, eingecheckt) sind getrennt.
const here = dirname(fileURLToPath(import.meta.url));
const ids = JSON.parse(readFileSync(join(here, '..', 'discord.json'), 'utf8'));

function need(name) {
  const v = process.env[name];
  if (!v || v === 'HIER_EINTRAGEN') {
    console.error(`[bot] ${name} fehlt in .env`);
    process.exit(1);
  }
  return v;
}

function needId(path, value) {
  if (!value) {
    console.error(`[bot] ${path} fehlt in discord.json`);
    process.exit(1);
  }
  return value;
}

const logChannels = {};
for (const [cat, id] of Object.entries(ids.logChannels || {})) logChannels[cat] = id || null;

export const config = {
  token: need('DISCORD_TOKEN'),
  guildId: needId('guildId', ids.guildId),
  welcome: {
    channelId: needId('welcome.channelId', ids.welcome?.channelId),
    messageId: needId('welcome.messageId', ids.welcome?.messageId),
    emoji: ids.welcome?.emoji || '✅',
  },
  roles: {
    whitelist: needId('roles.whitelist', ids.roles?.whitelist),
    einwohner: ids.roles?.einwohner || null,
  },
  logChannels,
  // Discord-Rollen-IDs des Teams (discord.json → teamRoles); fehlende Einträge werden nicht gespiegelt
  teamRoles: ids.teamRoles || {},
  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    database: process.env.DB_NAME || 'tacov',
    user: process.env.DB_USER || 'tacov',
    password: need('DB_PASS'),
  },
  logPollSeconds: Number(process.env.LOG_POLL_SECONDS || 5),
};
