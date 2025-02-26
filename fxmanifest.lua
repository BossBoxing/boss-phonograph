fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'boss-phonograph'
author 'BossDev'
version '0.0.1'

jo_libs {
    'menu',
}

shared_scripts {
    '@jo_libs/init.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    's/*.lua'
}

client_scripts {
    'c/*.lua',
}

ui_page {
    'nui://jo_libs/nui/index.html'
}

dependencies {
    'rsg-core',
    'rsg-target',
    'ox_lib'
}

lua54 'yes'
