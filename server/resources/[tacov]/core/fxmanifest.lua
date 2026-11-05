fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tacov_core'
description 'TacoV Kern: Spieler, Charaktere, Konten, Items, Rechte, Journal, Config'
version '0.1.0'

dependency 'oxmysql'

shared_scripts {
  'shared/util.lua',
  'config/core.lua',
  'config/economy.lua',
  'config/permissions.lua',
  'config/commands.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/db.lua',
  'server/migrations.lua',
  'server/log.lua',
  'server/journal.lua',
  'server/permissions.lua',
  'server/players.lua',
  'server/characters.lua',
  'server/accounts.lua',
  'server/needs.lua',
  'server/connect.lua',
  'server/commands.lua',
  'server/main.lua',
}

client_scripts {
  'client/main.lua',
  'client/ui.lua',
  'client/hud.lua',
  'client/keys.lua',
}

ui_page 'ui/index.html'

files {
  'ui/index.html',
  'ui/app.js',
  'ui/app.css',
  'ui/assets/*',
}
