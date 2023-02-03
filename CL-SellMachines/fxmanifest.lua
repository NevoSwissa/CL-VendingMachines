fx_version 'adamant'

game 'gta5'
lua54 'yes'
author "NevoSwissa#0111"

client_scripts {
    '@PolyZone/CircleZone.lua',
    '@PolyZone/client.lua',
    'client/client.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'config.lua',
}

dependencies {
    'PolyZone',
    'qb-target'
}