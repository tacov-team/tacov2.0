import { Client, GatewayIntentBits, Partials } from 'discord.js';
import { config } from './config.js';
import { handleReaction, handleReactionRemoved, handleMemberUpdate } from './whitelist.js';
import { startLogMirror } from './logs.js';
import { pool } from './db.js';

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMembers,
    GatewayIntentBits.GuildMessageReactions,
    GatewayIntentBits.DirectMessages,
  ],
  partials: [Partials.Message, Partials.Reaction, Partials.Channel],
});

client.once('clientReady', async () => {
  console.log(`[bot] angemeldet als ${client.user.tag}`);
  try {
    await pool.query('SELECT 1');
    console.log('[bot] Datenbank verbunden');
  } catch (e) {
    console.error('[bot] Datenbank nicht erreichbar:', e.message);
    process.exit(1);
  }
  // Willkommensnachricht in den Cache holen, damit Reaktionen darauf ankommen
  const ch = await client.channels.fetch(config.welcome.channelId).catch((e) => { console.warn('[bot] Willkommenskanal nicht erreichbar:', e.message); return null; });
  if (ch) {
    const msg = await ch.messages.fetch(config.welcome.messageId).catch((e) => { console.warn('[bot] Willkommensnachricht nicht gefunden:', e.message); return null; });
    // Bot setzt die Reaktion selbst vor, damit Neue nur noch draufklicken müssen
    if (msg) await msg.react(config.welcome.emoji).catch((e) => console.warn('[bot] Reaktion setzen:', e.message));
  }
  await startLogMirror(client);
});

client.on('messageReactionAdd', (reaction, user) => handleReaction(reaction, user, client).catch((e) => console.error('[bot] Reaktion', e)));
client.on('messageReactionRemove', (reaction, user) => handleReactionRemoved(reaction, user).catch(() => {}));
client.on('guildMemberUpdate', (o, n) => handleMemberUpdate(o, n).catch((e) => console.error('[bot] Rollen', e)));

process.on('unhandledRejection', (e) => console.error('[bot] unbehandelt', e));
client.login(config.token);
