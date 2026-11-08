fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tacov_core'
description 'TacoV Kern: Spieler, Charaktere, Konten, Items, Rechte, Journal, Config'
version '0.1.0'

dependency 'tacov_db'

shared_scripts {
  'shared/util.lua',
  'config/core.lua',
  'config/economy.lua',
  'config/permissions.lua',
  'config/commands.lua',
  'config/items.lua',
  'config/locations.lua',
  'config/shops.lua',
  'config/vehicles.lua',
  'config/dmv.lua',
  'config/workshop.lua',
  'config/traffic.lua',
}

server_scripts {
  'server/db.lua',
  'server/migrations.lua',
  'server/log.lua',
  'server/journal.lua',
  'server/permissions.lua',
  'server/players.lua',
  'server/characters.lua',
  'server/accounts.lua',
  'server/needs.lua',
  'server/inventory.lua',
  'server/locations.lua',
  'server/bank.lua',
  'server/shops.lua',
  'server/vehicles.lua',
  'server/dmv.lua',
  'server/workshop.lua',
  'server/traffic.lua',
  'server/admin.lua',
  'server/access.lua',
  'server/creator.lua',
  'server/doors.lua',
  'server/teleports.lua',
  'server/connect.lua',
  'server/commands.lua',
  'server/status.lua',
  'server/main.lua',
}

client_scripts {
  'client/main.lua',
  'client/ui.lua',
  'client/menu.lua',
  'client/voice.lua',
  'client/hud.lua',
  'client/locations.lua',
  'client/prompt.lua',
  'client/inventory.lua',
  'client/interact.lua',
  'client/bank.lua',
  'client/shops.lua',
  'client/vehicles.lua',
  'client/dmv.lua',
  'client/workshop.lua',
  'client/traffic.lua',
  'client/admin.lua',
  'client/creator.lua',
  'client/doors.lua',
  'client/teleports.lua',
  'client/keys.lua',
}

ui_page 'ui/index.html'

files {
  'ui/index.html',
  'ui/app.js',
  'ui/app.css',
  'ui/assets/*',
  'ui/assets/items/*',
}
