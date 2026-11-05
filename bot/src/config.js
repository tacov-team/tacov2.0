import 'dotenv/config';

function need(name) {
  const v = process.env[name];
  if (!v || v === 'HIER_EINTRAGEN') {
    console.error(`[bot] ${name} fehlt in .env`);
    process.exit(1);
  }
  return v;
}

export const config = {
  token: need('DISCORD_TOKEN'),
  guildId: need('DISCORD_GUILD_ID'),
  welcome: {
    channelId: need('WELCOME_CHANNEL_ID'),
    messageId: need('WELCOME_MESSAGE_ID'),
    emoji: process.env.WELCOME_EMOJI || '✅',
  },
  roles: {
    whitelist: need('ROLE_WHITELIST_ID'),
    einwohner: process.env.ROLE_EINWOHNER_ID || null,
  },
  // Kategorie -> Kanal-ID; Kategorien entsprechen server/log.lua
  logChannels: {
    connect: process.env.LOG_CONNECT || null,
    character: process.env.LOG_CHARACTER || null,
    money: process.env.LOG_MONEY || null,
    items: process.env.LOG_ITEMS || null,
    faction: process.env.LOG_FACTION || null,
    police: process.env.LOG_POLICE || null,
    medic: process.env.LOG_MEDIC || null,
    justice: process.env.LOG_JUSTICE || null,
    crime: process.env.LOG_CRIME || null,
    admin: process.env.LOG_ADMIN || null,
    support: process.env.LOG_SUPPORT || null,
  },
  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    database: process.env.DB_NAME || 'tacov',
    user: process.env.DB_USER || 'tacov',
    password: need('DB_PASS'),
  },
  logPollSeconds: Number(process.env.LOG_POLL_SECONDS || 5),
};
