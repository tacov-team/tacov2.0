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
  'config/peds.lua',
  'config/world.lua',
  'config/anticheat.lua',
  'config/clothing.lua',
  'config/tattoos.lua',
  'config/housing.lua',
  'config/animations.lua',
  'config/health.lua',
  'config/fitness.lua',
  'config/phone.lua',
  'shared/configedit.lua',
  'shared/clothingprice.lua',
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
  'server/peds.lua',
  'server/world.lua',
  'server/refunds.lua',
  'server/weather.lua',
  'server/configedit.lua',
  'server/devtools.lua',
  'server/tickets.lua',
  'server/anticheat.lua',
  'server/clothing.lua',
  'server/immigration.lua',
  'server/housing.lua',
  'server/newbie.lua',
  'server/health.lua',
  'server/fitness.lua',
  'server/phone.lua',
  'server/connect.lua',
  'server/commands.lua',
  'server/status.lua',
  'server/main.lua',
}

client_scripts {
  'client/appearance.lua',
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
  'client/peds.lua',
  'client/world.lua',
  'client/weather.lua',
  'client/configedit.lua',
  'client/devtools.lua',
  'client/clothing.lua',
  'client/immigration.lua',
  'client/housing.lua',
  'client/animations.lua',
  'client/health.lua',
  'client/fitness.lua',
  'client/phone.lua',
  'client/keys.lua',
}

ui_page 'ui/index.html'

loadscreen 'loadscreen/index.html'
loadscreen_manual_shutdown 'yes'

files {
  'loadscreen/index.html',
  'ui/index.html',
  'ui/app.js',
  'ui/app.css',
  'ui/assets/*',
  'ui/assets/items/*',
}
