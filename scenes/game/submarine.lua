local M = {}

local composer = require( "composer" )

local physics = require( "physics" )

local savedata = require( "scenes.libs.savedata" )

-- submarine vars
local submarine

local submarineIsRising
local touchActive

local group
local bubbleGroup

local submarineSkin
local bubbleSkin

-- constant vars
local submarineUpForce = 15
local submarineGravityScale = 4

-- submarine assets dir
local submarineDir = "assets/submarine/"
local bubbleDir = "assets/submarine/bubble/"


-- ----------------------------------------------------------------------------
-- private functions
-- ----------------------------------------------------------------------------

local function moveSubmarine( self, event )
	
	local rotDeg = 15 -- rotation degree
	local rotTimeUp = 800 -- rotation time up
	local rotTimeDown = 1100-- rotation time down

	-- start of touch
    if ( event.phase == "began" or event.phase == "down" ) then 
		 -- Set touch focus on the submarine (this means that the submarine object will "own" the touch event throughout its duration)
		display.currentStage:setFocus( self )

		-- set touch as active
		touchActive = true

		-- rise of submarine
		submarineIsRising = true

		-- rotate submarine
		transition.cancel( self )
		transRot = transition.to( self, { rotation = -rotDeg, time = rotTimeUp } )
	
	elseif ( event.phase == "ended" or event.phase == "cancelled" or event.phase == "up" ) then
		-- Release touch focus on the ship
		display.currentStage:setFocus( nil )

		-- set touch as inactive
		touchActive = false

		-- fall of submarine
		submarineIsRising = false

		-- change rotation
		transition.cancel( self )
		transRot = transition.to( self, { rotation = rotDeg, time = rotTimeDown } )
	end
	
    return true  -- Prevents touch propagation to underlying objects
end

local function onEnterFrame( self, event )

	local rotTime = 150

	-- apply force to move the submarine
	if ( touchActive ) then
		self:applyForce( 0, -submarineUpForce, self.x, self.y )
	end
	
	-- check bounds of submarine rotation
	if (submarineIsRising == true and self.y < 75) then
		submarineIsRising = false
		transition.cancel( self )
		transition.to( self, { rotation = 0, time = rotTime } )
	
	elseif (submarineIsRising == false and self.y > display.contentHeight-75) then
		submarineIsRising = true
		transition.cancel( self )
		transition.to( self, { rotation = 0, time = rotTime } )
	end
end

local function spawnBubble()

	local gameSpeed = composer.getVariable( "gameSpeed" )

	-- load bubble skin
	local bubblePaint = {
		type = "image",
		filename = bubbleDir .. bubbleSkin .. ".png"
	}

	-- create bubble
	newBubble = display.newRect( bubbleGroup, submarine.x-120, submarine.y+15, 85, 85 )
	newBubble.fill = bubblePaint
	local collFiltParams = composer.getVariable( "collFiltParams" ) -- get collision filter params
	physics.addBody( newBubble, "kinematic", { isSensor=true, filter=collFiltParams.submarineBubbleFilter } )
	
	-- set random scale
	local randScale = math.random( 10, 50 ) / 100
	newBubble.xScale = randScale
	newBubble.yScale = randScale

	-- add to table
	table.insert( composer.getVariable( "screenObjectsTable" ), newBubble )

	-- set speed and random y direction
	local randY = math.random( -100, 100 )
	newBubble:setLinearVelocity( -350*gameSpeed, randY )	
end


-- ----------------------------------------------------------------------------
-- public functions
-- ----------------------------------------------------------------------------

-- insert in scene:create()
function M.create( submarineGroup, mainGroup )
    
    -- init vars
    submarine = nil
	submarineIsRising = false
	touchActive = false
	group = submarineGroup
	bubbleGroup = mainGroup
	submarineSkin = savedata.getGamedata( "submarineSkin" )
	bubbleSkin = savedata.getGamedata( "submarineBubbleSkin" )

	-- load submarine skin
	local submarinePaint = {
		type = "image",
		filename = submarineDir .. submarineSkin .. ".png"
	}

	-- set submarine image scale factor
	local scaleFact = 0.50

	-- create submarine obj
	submarine = display.newRect( group, display.contentCenterX - (display.contentWidth*0.34), display.contentCenterY, 512*scaleFact, 265*scaleFact )
	submarine.fill = submarinePaint

	-- set physics
	local collFiltParams = composer.getVariable( "collFiltParams" ) -- get collision filter params
	physics.addBody( submarine, { radius=70, bounce=0, filter=collFiltParams.submarineFilter } )
	submarine.myName = "submarine"

	-- set gravity scale
	submarine.gravityScale = submarineGravityScale
	
    -- set event listener to move the submarine
    submarine.touch = moveSubmarine
	submarine.key = moveSubmarine
    Runtime:addEventListener( "touch", submarine )
	Runtime:addEventListener( "key", submarine )
    
    -- set event listener onEnterFrame function
    submarine.enterFrame = onEnterFrame
	Runtime:addEventListener( "enterFrame", submarine )
	
	-- set bubble spawner
	bubbleSpawnTimer = timer.performWithDelay( 100, spawnBubble, 0 )

	-- create physical bodies as bounds for the submarine
	-- no need to access these vars elsewhere in the code so we keep them local here
	local collFiltParams = composer.getVariable( "collFiltParams" ) -- get collision filter params

	local floor = display.newRect( group, submarine.x, display.contentHeight, 300, 1 )
	floor.isVisible = false
	physics.addBody( floor, "static", { bounce=0, filter=collFiltParams.submarinePlatformFilter } )

	local ceiling = display.newRect( group, submarine.x, 0, 300, 1 )
	ceiling.isVisible = false
	physics.addBody( ceiling, "static", { bounce=0, filter=collFiltParams.submarinePlatformFilter } )

end

-- insert in scene:hide() in "did" phase
function M.hideDid()

    -- remove Runtime listeners
    Runtime:removeEventListener( "touch", submarine )
	Runtime:removeEventListener( "key", submarine )
    Runtime:removeEventListener( "enterFrame", submarine )
	
	-- cancel timers
	timer.cancel( bubbleSpawnTimer )

    -- cancel transitions
	
end

-- cancel all transitions on the submarine object
function M.cancAllSubTrans()
	transition.cancel( submarine )
end

-- return module table
return M
