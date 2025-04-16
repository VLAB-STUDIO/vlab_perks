fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

lua54 'yes'
author '𝐕𝐋𝐀𝐁 𝐒𝐭𝐮𝐝𝐢𝐨 @𝗔͟𝘅𝗲̅𝗲̅𝗹𝗪͟𝗭'

shared_script {
    'shared/*.lua'
}

server_scripts {
    'server/*.lua'
}

client_script {
    '@vorp_core/client/dataview.lua',
    'client/*.lua'
}

files {
    'html/*.html',
    'html/*.css',
    'html/*.js',
    'html/fonts/milonga.ttf',
    'html/img/*.png',
    'html/sound/*.mp3'
}

ui_page 'html/index.html'