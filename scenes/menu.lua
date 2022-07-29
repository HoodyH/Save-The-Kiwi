
local composer = require( "composer" )

local physics = require( "physics" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

-- initialize variables -------------------------------------------------------

local fadeOutGame = 1400-- time to switch in game Mode


-- Load all the neades modules
local bgMod = require( "scenes.menu.background" ) -- load background module
local titleMod = require( "scenes.menu.title" ) -- to display title and floating objects
local savedata = require( "scenes.libs.savedata" ) -- load the save data module
local uiMod = require( "scenes.libs.ui" ) -- ui lib to show buttons in the interface
local audioMod = require( "scenes.libs.audio" ) -- load lib to do audio changes on the game

-- display groups
local uiGroup

-- audio
local menuTrack
local menuTrackPlayer
local getMoneySound

local updateMovementTimer

local fontParams

local moneyText -- value to where is stored the money text to be updated


-- update the money amount
function scene:updateMoneyView()
	moneyText.text = savedata.getGamedata( "money" ) .. '$'
end


-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	physics.pause()  -- Temporarily pause the physics engine (we don't want things to start yet)
	
	-- set up groups for display objects
	local bgGroup1 = display.newGroup() -- display group for background and for the title
	sceneGroup:insert( bgGroup1 ) -- insert into the scene's view group
	bgMod.init( bgGroup1 ) -- load and set background module

	-- load the title and the floating objects
	local bgGroup2 = display.newGroup()
	sceneGroup:insert( bgGroup2 )
	titleMod.init( bgGroup2 )
	updateMovementTimer = timer.performWithDelay( 2000, titleMod.updateMovement , 0)

	uiGroup = display.newGroup() -- display group for UI
	sceneGroup:insert( uiGroup ) -- insert into the scene's view group

	-- load music
	menuTrack = audio.loadStream( composer.getVariable( "audioDir" ) .. "menu.mp3" )
	getMoneySound = audio.loadStream( composer.getVariable( "audioDir" ) .. "sfx/getMoney.mp3" )

	-- load the global fonts params
	fontParams = composer.getVariable( "defaultFontParams" )


	-- ----------------------------------------------------------------------------
	-- main cental buttons
	-- ----------------------------------------------------------------------------
	local function playCallback() 
		audio.play( audioMod.buttonPlaySound )
		composer.gotoScene( "scenes.game", { time=fadeOutGame, effect="slideLeft" } )
	end 

	local function scoresCallback()
		composer.showOverlay( "scenes.menu.scores", { time=composer.getVariable( "windowFadingOpenTime" ), effect="fade" } )
	end

	local function aboutCallback()
		composer.showOverlay( "scenes.menu.about", { time=composer.getVariable( "windowFadingOpenTime" ), effect="fade" } )
	end

	local buttonsDescriptor = {
		descriptor = {
			{ "buttonPlay2.png", playCallback },
			{ "buttonScores.png", scoresCallback },
			{ "buttonAbout.png", aboutCallback }
		},
		propagation = 'down',
		position = 'center',
		scaleFactor = 0.6
	}
	uiMod.init(uiGroup, buttonsDescriptor)	
	

	-- ----------------------------------------------------------------------------
	-- top right bagdes
	-- ----------------------------------------------------------------------------
	local function muteMusicCallback()
		audio.play( audioMod.buttonClickSound )
		audioMod.toggleMusic()
	end

	local function worldsMenuCallback() 
		composer.showOverlay( "scenes.settings.worlds", { time=composer.getVariable( "windowFadingOpenTime" ), effect="fade" } )
	end

	local function submarinesMenuCallback() 
		composer.showOverlay( "scenes.settings.submarines", { time=composer.getVariable( "windowFadingOpenTime" ), effect="fade" } )
	end

	local function bubblesMenuCallback() 
		composer.showOverlay( "scenes.settings.bubbles", { time=composer.getVariable( "windowFadingOpenTime" ), effect="fade" } )
	end

	local function settingsCallback( event ) 
		audio.play( audioMod.buttonClickSound )
	end
	
	-- load the badges in the list
	-- with the packIcon declared the menu will pack under the packIcon as hamburger menu
	local badgesDescriptor = {
		packIcon = "badgeSettings.png", -- activate the pack system with this icon
		packCallback = settingsCallback,
		packRotation = 360,
		descriptor={
			{"badgeEdit.png", worldsMenuCallback },
			{"badgeSubmarine.png", submarinesMenuCallback },
			{"badgeBubbles.png", bubblesMenuCallback },
			{"badgeMute.png", muteMusicCallback}
		},
		propagationOffsetY = 160,
		propagation = 'down',

	}
	uiMod.init(uiGroup, badgesDescriptor)

	
	-- ----------------------------------------------------------------------------
	-- money display
	-- ----------------------------------------------------------------------------

	-- obtain the position of the settings badge, to align the money display  
	local xPosition, yPosition = uiMod.getPosition()

	-- load the badge where display the money value
	local moneyBadge = display.newImage( uiGroup, "assets/ui/badgeMoney.png" ) -- set mask
	moneyBadge:scale( 0.3, 0.3 )
	moneyBadge.x = xPosition - 280
	moneyBadge.y = yPosition, 
	moneyBadge:addEventListener( 
		"tap", 
		function ()
			-- give user money each time he tap on the money display 
			savedata.setGamedata( "money", savedata.getGamedata( "money" ) + 400 )
			audio.play( getMoneySound )
			scene.updateMoneyView()
		end
	)

	-- print the text over the badge
    moneyText = display.newText( 
		uiGroup, 
		savedata.getGamedata( "money" ) .. '$',
		moneyBadge.x, 
		moneyBadge.y, 
		fontParams.path, 
		70 
	)
	moneyText:setFillColor( fontParams.colorR, fontParams.colorG, fontParams.colorB )


	-- ----------------------------------------------------------------------------
	-- bottom row text
	-- ----------------------------------------------------------------------------
	
	-- show version
	local versionStamp = display.newText( 
        uiGroup, 
        'v ' .. composer.getVariable( "version" ), 
        display.contentCenterX - display.contentWidth/2.5, 
        display.contentCenterY + display.contentHeight/2.3, 
        fontParams.path, 
        50 
	)
	versionStamp:setFillColor( fontParams.colorR, fontParams.colorG, fontParams.colorB )

	-- show label: Game Programming Lab
	local gameProgrammingStamp = display.newText( 
        uiGroup, 
        'Laboratorio di Game Programming', 
        display.contentCenterX + display.contentWidth/4.1, 
        display.contentCenterY + display.contentHeight/2.3, 
        fontParams.path, 
        50 
	)
	gameProgrammingStamp:setFillColor( fontParams.colorR, fontParams.colorG, fontParams.colorB )
end


function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "did" ) then -- Code here runs when the scene is entirely on screen

		-- re-start physics engine ( previously stopped in create() )
		physics.start()
		
		menuTrackPlayer = audio.play( menuTrack, { channel=1, loops=-1 } )
	end
end


function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		timer.cancel( updateMovementTimer ) 
		
	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

		bgMod.clear() -- clear background

		-- stop all audio playing
		audio.stop()

		menuTrackPlayer = nil

		-- remove the scene from cache 
		-- NOTE: this function entirely removes the scene and all the objects and variables inside,
		--		in particular it takes care of display.remove() all display objects inside sceneGroup hierarchy
		--		but NOTE that it doesn't remove things like timers or listeners attached to the "Runtime" object (so we took care of them manually)
		composer.removeScene( "scenes.menu" )
	end
end


-- destroy()
function scene:destroy( event )
	
	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

	-- dispose loaded audio
	audio.dispose( menuTrack )
	audio.dispose( getMoneySound )
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
