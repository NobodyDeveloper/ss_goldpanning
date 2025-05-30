fx_version 'cerulean'

game 'gta5'

author 'ShoeShuffler'

description 'Shuffle Shop GoldPanning!'

version '1.0.0'

lua54 'yes'



client_scripts{
	'@qbx_core/modules/playerdata.lua',
	'client/**.lua',
}

server_scripts{
	'server/**.lua',
	'@oxmysql/lib/MySQL.lua',
}

 shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
	'@qbx_core/modules/lib.lua',
 }

 files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
    'html/audio/*.mp3',
    'html/img/*.*',
    'stream/fullbowl.ytyp',
    'stream/*.ydr',
    'locales/*.json'
}

escrow_ignore {
    'locales/*.json',
    'config.lua',
    'server/sv_functions.lua',
}

data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

ui_page('html/index.html')