
local composer = require( "composer" )

-- set audio root dir globally (this is done to simplify the introduction of different audio packs)
composer.setVariable( "audioDir", "audio/" )

local M = {
    buttonPlaySound = audio.loadSound( composer.getVariable( "audioDir" ) .. "sfx/staiZitta.mp3" ),
    buttonClickSound = audio.loadSound( composer.getVariable( "audioDir" ) .. "sfx/click.mp3" ),
    buttonCloseSound = audio.loadSound( composer.getVariable( "audioDir" ) .. "sfx/close.mp3" ),
    buttonClickSound = audio.loadSound( composer.getVariable( "audioDir" ) .. "sfx/click.mp3" ),
    buttonSelectSound = audio.loadSound( composer.getVariable( "audioDir" ) .. "sfx/select.mp3" ),
    paySound = audio.loadSound( composer.getVariable( "audioDir" ) .. "sfx/pay.mp3" ),
    noMoneySound = audio.loadSound( composer.getVariable( "audioDir" ) .. "sfx/noMoney.mp3" ),
}

-- load the savedata module
local savedata = require( "scenes.libs.savedata" )


function M.toggleMusic()

    local audioMute = savedata.getGamedata( "audioMute" )
    if audioMute then
        audio.setVolume( 0.5, { channel=1 } )
        savedata.setGamedata( "audioMute", false)
    else
        audio.setVolume( 0, { channel=1 } )
        savedata.setGamedata( "audioMute", true)
    end 
end


function M.setFromSave()
    local audioMute = savedata.getGamedata( "audioMute" )

    if audioMute then
        audio.setVolume( 0, { channel=1 } )
    else
        audio.setVolume( 0.5, { channel=1 } )
    end
end 


-- return module table
return M
