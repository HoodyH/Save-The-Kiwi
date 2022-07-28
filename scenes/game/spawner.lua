local M = {}

local composer = require( "composer" )

local physics = require( "physics" )

-- define vars
local spawnHandlerTimer

local group

local lastSpawnGroundObjects
local lastSpawnFloatingObjects
local lastSpawnObstacle
local lastSpawnObsSeq

local outlineCache -- to reduce CPU usage

-- assets dir
local pickDir = "assets/items/pickables/" -- pickables dir
local obsDir = "assets/items/obstacles/" -- obstacles dir


-- ----------------------------------------------------------------------------
-- private functions
-- ----------------------------------------------------------------------------

local function spawnGroundObjects()

    local gameSpeed = composer.getVariable( "gameSpeed" )

    -- spawn cooldown
    local spawnCooldown = 10/gameSpeed -- cooldown seconds
    if ( (os.time() - lastSpawnGroundObjects) < spawnCooldown ) then
        return
    end
    lastSpawnGroundObjects = os.time()

    -- generate a random number of pickable items
    local randNum = math.random( 1, math.floor(gameSpeed)+1 ) 
    for i=1, randNum do

        -- select random asset
        local randAsset = math.random( 5 )
        local paint = {
            type = "image",
            filename = pickDir .. "barrel/" .. randAsset .. ".png"
        }
        
        -- create object
        local scaleFact = 0.18
        local newPickable = display.newRect( group, display.contentWidth + math.random(600, 1400), display.contentHeight, 349*scaleFact, 512*scaleFact )
        newPickable.fill = paint
        newPickable.anchorY = 1
        newPickable.myType = "pickableObject"
        newPickable.myName = "groundObject"
        newPickable.mySeaLife = true -- used in updateSeaLife() to avoid counting the same object more than 1 time
        local collFiltParams = composer.getVariable( "collFiltParams" ) -- get collision filter params
        physics.addBody( newPickable, { radius=50, isSensor=true, filter=collFiltParams.pickableObjectFilter } )
        newPickable.gravityScale = 0 -- remove gravity from this

        -- rand rotation
        local randRot = math.random( 2 )
        if (randRot == 2) then
            newPickable.rotation = 90
            newPickable.y = newPickable.y - 30
        end

        -- add to table
        table.insert( composer.getVariable( "screenObjectsTable" ), newPickable )

        -- set speed
        newPickable:setLinearVelocity( -450*gameSpeed, 0 )
    end
end

local function spawnFloatingObjects()

    local gameSpeed = composer.getVariable( "gameSpeed" )

    -- check spawn cooldown
    local spawnCooldown = 6/gameSpeed -- cooldown seconds
    if ( (os.time() - lastSpawnFloatingObjects) < spawnCooldown ) then
        return
    end
    lastSpawnFloatingObjects = os.time()

    -- set random spawn center on the Y axis
    local spawnCenterY = math.random(400, display.contentHeight-400)

    -- generate a random number of pickable items
    local randNum = math.random( 2, math.floor(gameSpeed*2)+2 ) 
    for i=1, randNum do

        -- select random asset
        local randAsset = math.random( 5 )
        local paint = {
            type = "image",
            filename = pickDir .. "bottle/" .. randAsset .. ".png"
        }
        
        -- create object
        local scaleFact = 0.28
        local spawnPosY = math.random( spawnCenterY - 100, spawnCenterY + 100 )
        local spawnPosX = display.contentWidth + 450 + (i * 150) + math.random( -50, 50 )
        local newPickable = display.newRect( group, spawnPosX, spawnPosY, 512*scaleFact, 512*scaleFact )
        newPickable.fill = paint
        newPickable.myType = "pickableObject"
        newPickable.myName = "floatingObject"
        newPickable.mySeaLife = true -- used in updateSeaLife() to avoid counting the same object more than 1 time
        local collFiltParams = composer.getVariable( "collFiltParams" ) -- get collision filter params
        physics.addBody( newPickable, { radius=50, isSensor=true, filter=collFiltParams.pickableObjectFilter } )
        newPickable.gravityScale = 0 -- remove gravity from this

        -- rand spin
        local randRot = math.random( -8, 8 )
        newPickable:applyTorque( randRot )

        -- add to table
        table.insert( composer.getVariable( "screenObjectsTable" ), newPickable )

        -- set speed
        newPickable:setLinearVelocity( -450*gameSpeed, 0 )
    end
end

local function spawnObstacle( assetPath, location, xPos, yPos, linearVelocity )

    -- select asset with random scale
    -- NOTE: here we use assets already scaled because outline function works on
    --          the real dimension in pixels of the asset to be outlined
    local assetPathScaled = assetPath .. "x" .. math.random( 12, 15 ) .. ".png"
    
    -- outline asset image
    -- NOTE: here we dynamically cache the graphics.newOutline() output to improve perfomance and reduce CPU usage
    if ( outlineCache[ assetPathScaled ] == nil ) then
        outlineCache[ assetPathScaled ] = graphics.newOutline( 2, assetPathScaled )
    end
    
    local assetOutline = outlineCache[ assetPathScaled ]
    
    -- create object and select the right scale
    local newObstacle = display.newImage( group, assetPathScaled, xPos, yPos )
    newObstacle.myType = "obstacleObject"
    newObstacle.myName = "obstacle"

    -- adapt to location
    if ( location == "floor" ) then
        newObstacle.anchorY = 1

    elseif ( location == "ceiling" ) then
        newObstacle.rotation = 180
        newObstacle.anchorY = 1
    end
    
    -- set physics
    local collFiltParams = composer.getVariable( "collFiltParams" ) -- get collision filter params
    physics.addBody( newObstacle, "kinematic", { isSensor=true, outline=assetOutline,filter=collFiltParams.obstacleFilter } )

    -- add to table
    table.insert( composer.getVariable( "screenObjectsTable" ), newObstacle )

    -- set speed
    newObstacle:setLinearVelocity( linearVelocity, 0 ) 
end

local function spawnObstacleSequence ( length, location ) 

    local gameSpeed = composer.getVariable( "gameSpeed" )

    for i=1, length do
        -- set random obstlacle properties and spawn it
        local assetPath = obsDir .. "stone/" .. math.random( 1, 2 )
        local linearVelocity = -450 * gameSpeed
        local xPos = display.contentWidth + 300 + (350 * i)
        if ( location == "mix" ) then
            if ( math.random( 2 ) == 1 ) then
                spawnObstacle( assetPath, "floor", xPos, display.contentHeight+30, linearVelocity )
            else
                spawnObstacle( assetPath, "ceiling", xPos, -20, linearVelocity )
            end
        elseif ( location == "floor" ) then
            spawnObstacle( assetPath, "floor", xPos, display.contentHeight+20, linearVelocity )
        else
            spawnObstacle( assetPath, "ceiling", xPos, -20, linearVelocity )
        end
    end
end

local function spawnHandler()

    local gameSpeed = composer.getVariable( "gameSpeed" )

    -- select random spawn event based on probabilities
    local randEvent = math.random( 100 )

    if ( randEvent <= 85 ) then -- 85% prob of pickable objects or single obstacle
        -- select random spawn object based on probabilities
        local randObj = math.random( 100 )

        if ( randObj <= 45 ) then -- 45% prob of floating obj
            spawnFloatingObjects()

        elseif ( randObj <= 80 ) then -- 35% prob of ground obj
            spawnGroundObjects()
    
        elseif ( randObj <= 100 ) then -- 20% prob of obstacle
            -- check cooldowns
            local obstacleSpawnCooldown = 8/gameSpeed -- cooldown seconds
            if ( (os.time() - lastSpawnObstacle) < obstacleSpawnCooldown ) then
                return
            end
            lastSpawnObstacle = os.time()

            -- set random obstlacle properties and spawn it
            local linearVelocity = -450 * gameSpeed
            local xPos = display.contentWidth + 600
            if ( math.random( 2 ) == 1 ) then
                local assetPath = obsDir .. "stone/" .. math.random( 3, 4 )
                spawnObstacle( assetPath, "floor", xPos, display.contentHeight+20, linearVelocity )
            else 
                local assetPath = obsDir .. "stone/" .. math.random( 1, 2 )
                spawnObstacle( assetPath, "ceiling", xPos, -20, linearVelocity )
            end
        end

    elseif ( randEvent <= 100 ) then -- 15% prob of obstacle sequence
        -- check cooldowns
        local obsSeqSpawnCooldown = 17/gameSpeed -- cooldown seconds
        if ( (os.time() - lastSpawnObsSeq) < obsSeqSpawnCooldown ) then
            return
        end
        lastSpawnObsSeq = os.time()

        -- select rand seq kind
        local randSeqKind = math.random( 6 ) 
        local randSeqLen = math.random( 8, 16 ) -- length of seq in pieces

        if ( randSeqKind == 1 ) then
            spawnObstacleSequence ( randSeqLen, "floor" ) -- 1/6 prob

        elseif ( randSeqKind == 2 ) then
            spawnObstacleSequence ( randSeqLen, "ceiling" ) -- 1/6 prob

        else
            spawnObstacleSequence ( randSeqLen, "mix" ) -- 4/6 prob
        end
    end
end


-- ----------------------------------------------------------------------------
-- public functions
-- ----------------------------------------------------------------------------

-- insert in scene:create()
function M.create( mainGroup )
    
    -- init vars
    group = mainGroup
    lastSpawnGroundObjects = os.time()
    lastSpawnFloatingObjects = os.time()
    lastSpawnObstacle = os.time()
    lastSpawnObsSeq = os.time()
    outlineCache = {}
end

-- insert in scene:show() in "did" phase
function M.showDid()

    -- set spawn timers
    spawnHandlerTimer = timer.performWithDelay( 500, spawnHandler, 0 )
end

-- insert in scene:hide() in "did" phase
function M.hideDid()

    -- remove Runtime listeners

    -- cancel timers
    timer.cancel( spawnHandlerTimer )

    -- cancel transitions

end

-- return module table
return M
