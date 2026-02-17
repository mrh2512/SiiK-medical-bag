fx_version 'cerulean'
game 'gta5'

author 'SiiK'
description 'Placeable Medical Bag'
version '1.0.0'

shared_scripts {
  '@qb-core/shared/locale.lua',
  'shared/config.lua',
}

client_scripts {
  'client/main.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua',
}

dependencies {
  'qb-core',
  'qb-target',
  'oxmysql'
}
