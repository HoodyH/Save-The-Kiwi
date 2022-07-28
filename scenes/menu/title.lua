local M = {}

local composer = require( "composer" )

local physics = require( "physics" )

local itemsDir = "assets/items/" -- dir to change between worlds

local group -- for the floating items and the title

local screenObjects
local screenObjectsNum = 6

local titleImmage


local function spawnFloatingObjects()
    
    -- relative dir, scale factor
    local items = {
        {"pickables/bottle/1.png", 0.3},
        {"pickables/barrel/4.png", 0.4},
        {"pickables/bag/2.png", 0.3},
        {"pickables/bag/3.png", 0.3},
        {"neutral/kiwi.png", 0.8},
        {"neutral/pearl1.png", 1.2},
        {"neutral/seahorse1.png", 1.2},
    }

    local offset = 512
    local cx, cy = display.contentCenterX, display.contentCenterY
    local cw, ch = display.contentWidth, display.contentHeight
    
    local topBumper = display.newRect( group, cx , 0-offset, cw*2, 1 )
    physics.addBody( topBumper, "static", { density=3.0, bounce=0.0 } )

    local bottomBumper = display.newRect( group, cx, ch+offset, cw*2, 1 )
    physics.addBody( bottomBumper, "static", { density=3.0, bounce=0.0 } )

    local leftBumper = display.newRect( group, 0-offset, cy, 1, ch*2 )
    physics.addBody( leftBumper, "static", { density=3.0, bounce=0.0 } )

    local rightBumper = display.newRect( group, cw+offset, cy, 1, ch+2 ) 
    physics.addBody( rightBumper, "static", { density=3.0, bounce=0.0 } )


    for count, el in pairs ( items ) do

        local dir = el[1]
        local scaleFactor = el[2]

        -- create object random coords
        local spawnPosY = math.random( 
            display.contentCenterY - display.contentHeight/2.2, 
            display.contentCenterY + display.contentHeight/2.2 
        )
        local spawnPosX = math.random( 
            display.contentCenterX - display.contentWidth/2.2,
            display.contentCenterX + display.contentWidth/2.2
        )

        local randRotation = math.random( -40, 40 ) -- generate a random rotation

        local item = display.newImage( group, itemsDir .. dir )
        item:scale( scaleFactor, scaleFactor )
        item.x = spawnPosX
        item.y = spawnPosY
        item.rotation = randRotation
        
        -- set the phisics
        physics.addBody( item, "dynamic", { density=3.0, bounce=0.3, radius=100 } )
        item.gravityScale = 0

        local randSpeedX = math.random( -12, 12 )
        local randSpeedY = math.random( -12, 12 )
        item:setLinearVelocity( randSpeedX, randSpeedY )

        item:applyAngularImpulse( randRotation * 50 )

        -- save the item for future actions
        table.insert( screenObjects, item )
    end
end


-- update the speed of the objects
function M.updateMovement()

    for count=1, #screenObjects do
        local randRotation = math.random( -30, 30 ) -- generate a random rotation
        screenObjects[count]:applyAngularImpulse( randRotation * 10 )
    end

end


-- init function
function M.init( viewGroup )

    -- the bgGroup1 mut be lower in gerarchie of bgGroup2
    -- becouse the bgGroup1 will be reloaded every world selectcion change

    group = viewGroup -- for the background

    screenObjects = {}

    -- spown the floating objects 
    spawnFloatingObjects()

    -- set title on the menu
	titleImmage = display.newImage(group, "assets/menu/menu1.png") -- set title
	titleImmage.x = display.contentCenterX
	titleImmage.y = display.contentCenterY
end


-- return module table
return M
