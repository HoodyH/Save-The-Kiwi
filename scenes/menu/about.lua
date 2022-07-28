local composer = require( "composer" )
local scene = composer.newScene()


-- initialize variables -------------------------------------------------------
local windowMod = require( "scenes.libs.window" )


-- to hide the current overlay
local function hideScene()
    composer.hideOverlay( "fade", composer.getVariable( "windowFadingClosingTime" ) )
end


function scene:create( event )

    local sceneGroup = self.view

    -- create a new display group
    local group = display.newGroup() 
    sceneGroup:insert( group )

    local windowsOptions = {
        onExitCallback = hideScene,
        windowTitle = "About"
    }
    windowMod.init( group, windowsOptions ) -- display the window

    -- set the about immage
    -- the callback will open the link to the github repo
    local aboutText = display.newImage(group, "assets/menu/about1.png")
	aboutText.x = display.contentCenterX - display.contentHeight/20
    aboutText.y = display.contentCenterY + display.contentHeight/10
    aboutText:addEventListener( 
        "tap",
        function () system.openURL( 'https://www.twitch.tv/pixelkewie' ) end 
    )
end


scene:addEventListener( "create", scene )

return scene
