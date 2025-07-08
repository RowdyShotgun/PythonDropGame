-- DropGame main.lua
-- Falling images game

-- Constants
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600
local GAME_TITLE = 'Drop Game'
local DEFAULT_OBJECT_SIZE = 40
local SPAWN_INTERVAL = 1.0
local MAX_OBJECTS_PER_TYPE = 5

-- Game States
local GAME_STATE_TITLE = 'title'
local GAME_STATE_PLAY = 'play'
local GAME_STATE_GAMEOVER = 'gameover'

-- Game Variables
local gameState = GAME_STATE_TITLE
local images = {} -- Stores loaded image objects
local fallingObjects = {} -- Stores active falling objects
local score = 0
local hasLost = false -- Renamed 'lose' for clarity
local spawnTimer = 0

-- Font Objects (load once)
local fontLarge
local fontMedium
local fontSmall

-- Object Configurations (indexed by image type)
local objectConfigs = {
    -- object1.png
    {speedMin = 100, speedMax = 150, drawColor = {1, 0, 0, 1}}, -- Red
    -- object2.png
    {speedMin = 160, speedMax = 210, drawColor = {0, 1, 0, 1}}, -- Green
    -- object3.png
    {speedMin = 220, speedMax = 270, drawColor = {0, 0, 1, 1}}, -- Blue
}

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.window.setTitle(GAME_TITLE)

    -- Load images. If a file is not found, the corresponding 'images' entry remains nil.
    -- The game will then draw a colored rectangle based on objectConfigs.
    images[1] = love.graphics.newImage('object1.png') or nil
    images[2] = love.graphics.newImage('object2.png') or nil
    images[3] = love.graphics.newImage('object3.png') or nil

    -- Initialize fonts once
    fontLarge = love.graphics.newFont(36)
    fontMedium = love.graphics.newFont(20)
    fontSmall = love.graphics.newFont(18)
end

-- Helper function to count active objects of a specific type
local function countObjectsOfType(typeIndex)
    local count = 0
    for _, obj in ipairs(fallingObjects) do
        if obj.typeIndex == typeIndex then
            count = count + 1
        end
    }
    return count
end

-- Function to spawn a new falling object
local function spawnObject()
    -- Determine which object types are currently under their maximum limit
    local availableTypes = {}
    for i = 1, #images do -- Iterate through all possible object types
        if countObjectsOfType(i) < MAX_OBJECTS_PER_TYPE then
            table.insert(availableTypes, i)
        end
    end

    if #availableTypes == 0 then return end -- If all types are at max, don't spawn

    -- Pick a random available type
    local imgIndex = availableTypes[love.math.random(1, #availableTypes)]
    local img = images[imgIndex]
    local size = img and img:getWidth() or DEFAULT_OBJECT_SIZE
    local config = objectConfigs[imgIndex] or {} -- Fallback to an empty table if config missing

    -- Default speeds if not specified in config
    local speedMin = config.speedMin or 100
    local speedMax = config.speedMax or 200

    table.insert(fallingObjects, {
        x = love.math.random(0, WINDOW_WIDTH - size),
        y = -size, -- Start above the screen
        speed = love.math.random(speedMin, speedMax),
        img = img,
        size = size,
        typeIndex = imgIndex,
        drawColor = config.drawColor or {1, 1, 1, 1} -- Default to white if not specified
    })
end

-- Resets the game state for a new round
local function resetGame()
    fallingObjects = {}
    score = 0
    hasLost = false
    spawnTimer = 0
}

function love.update(dt)
    if gameState == GAME_STATE_PLAY then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= SPAWN_INTERVAL then
            spawnObject()
            spawnTimer = 0
        end

        -- Update position of falling objects and check for game over
        for i = #fallingObjects, 1, -1 do
            local obj = fallingObjects[i]
            obj.y = obj.y + obj.speed * dt

            if obj.y > WINDOW_HEIGHT then
                gameState = GAME_STATE_GAMEOVER
                hasLost = true
                break -- Exit loop immediately on game over
            end
        }
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if gameState == GAME_STATE_TITLE then
            resetGame()
            gameState = GAME_STATE_PLAY
        elseif gameState == GAME_STATE_PLAY then
            -- Iterate backwards for safe removal/modification
            for i = #fallingObjects, 1, -1 do
                local obj = fallingObjects[i]
                local ox, oy, osize = obj.x, obj.y, obj.size

                -- Check if mouse click is within the object's bounds
                if x >= ox and x <= ox + osize and y >= oy and y <= oy + osize then
                    -- Instead of removing and re-adding, just reset its position
                    -- This is a simple form of object recycling.
                    obj.y = -obj.size -- Move to top to fall again
                    score = score + 1
                    break -- Assuming only one object can be clicked per click
                end
            }
        elseif gameState == GAME_STATE_GAMEOVER then
            gameState = GAME_STATE_TITLE
        end
    end
end

function love.draw()
    if gameState == GAME_STATE_TITLE then
        love.graphics.setFont(font