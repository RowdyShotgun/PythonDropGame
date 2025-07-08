--REMEMBER WITH OUR DEBUGGER F5 for debug, SHIFT F5 for non-debug
--This is your debug code. It goes at the very top of main.
if arg[2] == "debug" then
    require("lldebugger").start()
end

-- DropGame main.lua
local gameState = 'title' -- 'title', 'play', 'gameover'
local images = {}
local fallingObjects = {}
local score = 0
local backgroundClouds = nil
local backgroundSolidSky = nil
local powerupIcon = nil
local lose = false
local spawnTimer = 0
local spawnInterval = 1.0
local windowWidth, windowHeight = 1024, 768 -- Increased window size

-- Progressive difficulty system
local speedMod = 1
local baseSpeedMultiplier = 1.0

-- Powerup system
local powerup = {
    active = false,
    x = 50, -- Static position
    y = 50,
    size = 40,
    duration = 5.0, -- 5 seconds
    timer = 0,
    color = {0, 1, 0, 1} -- Green
}
local powerupActive = false
local powerupTimer = 0
local powerupDuration = 5.0
local originalSizes = {}
local originalSpeeds = {}

local objectConfigs = {
    {speedMin = 75, speedMax = 112}, 
    {speedMin = 85, speedMax = 157}, 
    {speedMin = 115, speedMax = 172},
}
local maxPerType = 5

function love.load()
    love.window.setMode(windowWidth, windowHeight)
    love.window.setTitle('Drop Game')
    
    -- Proper randomization setup
    math.randomseed(os.time())
    math.random(); math.random(); math.random()
    
    -- Load background clouds
    backgroundClouds = love.graphics.newImage('background_clouds.png')
    
    -- Load solid sky background
    backgroundSolidSky = love.graphics.newImage('background_solid_sky.png')
    
    -- Load powerup icon
    powerupIcon = love.graphics.newImage('snail_rest.png')
    
    -- Load images (use built-in shapes if no images available)
    images[1] = love.graphics.newImage('object1.png') or nil
    images[2] = love.graphics.newImage('object2.png') or nil
    images[3] = love.graphics.newImage('object3.png') or nil
    -- If images not found, fallback to nil (draw as circles)
end

local function countObjectsOfType(typeIndex)
    local count = 0
    for _, obj in ipairs(fallingObjects) do
        if obj.typeIndex == typeIndex then
            count = count + 1
        end
    end
    return count
end

local function spawnObject()
    -- Try to spawn a random type, but only if under maxPerType
    local availableTypes = {}
    for i = 1, #images do
        if countObjectsOfType(i) < maxPerType then
            table.insert(availableTypes, i)
        end
    end
    if #availableTypes == 0 then return end -- All types at max
    local imgIndex = availableTypes[love.math.random(1, #availableTypes)]
    local img = images[imgIndex]
    local size = img and img:getWidth() or 40
    
    -- Apply powerup effect if active
    if powerupActive then
        size = size * 0.6 -- Reduce size by 40%
    end
    
    local config = objectConfigs[imgIndex] or {speedMin=100, speedMax=200}
    
    -- Apply progressive difficulty to speed
    local adjustedSpeedMin = config.speedMin * baseSpeedMultiplier
    local adjustedSpeedMax = config.speedMax * baseSpeedMultiplier
    
    -- Apply powerup effect if active
    if powerupActive then
        adjustedSpeedMin = adjustedSpeedMin * 0.5 -- Slow down by 50%
        adjustedSpeedMax = adjustedSpeedMax * 0.5
    end
    
    table.insert(fallingObjects, {
        x = love.math.random(0, windowWidth - size),
        y = -size,
        speed = love.math.random(adjustedSpeedMin, adjustedSpeedMax),
        img = img,
        size = size,
        typeIndex = imgIndex,
        originalSize = img and img:getWidth() or 40 -- Store original size
    })
end

local function activatePowerup()
    powerupActive = true
    powerupTimer = 0
    
    -- Store original sizes and speeds
    for i, obj in ipairs(fallingObjects) do
        originalSizes[i] = obj.size
        originalSpeeds[i] = obj.speed
        
        -- Apply powerup effects to existing objects
        obj.size = obj.originalSize * 0.6
        obj.speed = obj.speed * 0.5
    end
    
    -- Hide the powerup
    powerup.active = false
end

local function deactivatePowerup()
    powerupActive = false
    
    -- Restore original sizes and speeds
    for i, obj in ipairs(fallingObjects) do
        if originalSizes[i] then
            obj.size = originalSizes[i]
        end
        if originalSpeeds[i] then
            obj.speed = originalSpeeds[i]
        end
    end
    
    -- Clear stored values
    originalSizes = {}
    originalSpeeds = {}
    
    -- Respawn powerup after a delay
    powerup.timer = 0
end

local function spawnPowerup()
    if not powerup.active and not powerupActive then
        powerup.active = true
        powerup.timer = 0
    end
end

function love.update(dt)
    if gameState == 'play' then
        -- Powerup spawning logic
        if not powerup.active and not powerupActive then
            powerup.timer = powerup.timer + dt
            if powerup.timer >= 10.0 then -- Spawn powerup every 10 seconds
                spawnPowerup()
            end
        end
        
        -- Powerup active timer
        if powerupActive then
            powerupTimer = powerupTimer + dt
            if powerupTimer >= powerupDuration then
                deactivatePowerup()
            end
        end
        
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            spawnObject()
            spawnTimer = 0
        end
        for i = #fallingObjects, 1, -1 do
            local obj = fallingObjects[i]
            obj.y = obj.y + obj.speed * dt
            if obj.y > windowHeight then
                gameState = 'gameover'
                lose = true
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if gameState == 'title' then
            gameState = 'play'
            fallingObjects = {}
            score = 0
            lose = false
            spawnTimer = 0
            speedMod = 1 -- Reset difficulty
            baseSpeedMultiplier = 1.0
            powerupActive = false
            powerupTimer = 0
            powerup.active = false
            powerup.timer = 0
            originalSizes = {}
            originalSpeeds = {}
        elseif gameState == 'play' then
            -- Check for powerup click first
            if powerup.active then
                if x >= powerup.x and x <= powerup.x + powerup.size and 
                   y >= powerup.y and y <= powerup.y + powerup.size then
                    activatePowerup()
                    return -- Don't check for object clicks
                end
            end
            
            for i = #fallingObjects, 1, -1 do
                local obj = fallingObjects[i]
                local ox, oy, osize = obj.x, obj.y, obj.size
                if x >= ox and x <= ox + osize and y >= oy and y <= oy + osize then
                    -- Progressive difficulty: increase speed for future objects
                    speedMod = speedMod + 1
                    baseSpeedMultiplier = 1.0 + (speedMod * 0.012) 
                    
                    -- Randomize position and speed for clicked object
                    obj.x = love.math.random(0, windowWidth - osize)
                    obj.y = -osize - love.math.random(0, osize * 2)
                    
                    -- Increase speed of this object
                    local config = objectConfigs[obj.typeIndex] or {speedMin=100, speedMax=200}
                    local newSpeed = love.math.random(config.speedMin, config.speedMax) * baseSpeedMultiplier
                    
                    -- Apply powerup effect if active
                    if powerupActive then
                        newSpeed = newSpeed * 0.5
                    end
                    
                    obj.speed = math.max(obj.speed, newSpeed) -- Can only get faster
                    
                    score = score + 1
                    break -- Only click one object at a time
                end
            end
        elseif gameState == 'gameover' then
            gameState = 'title'
        end
    end
end

function love.draw()
    if gameState == 'title' then
        -- Draw solid sky background for title screen
        if backgroundSolidSky then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(backgroundSolidSky, 0, 0, 0, windowWidth / backgroundSolidSky:getWidth(), windowHeight / backgroundSolidSky:getHeight())
        end
        
        love.graphics.setColor(0, 0, 0, 1) -- Set text color to black
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.printf('ALIEN BUSTER', 0, 200, windowWidth, 'center')
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf('Click to Start', 0, 300, windowWidth, 'center')
        love.graphics.printf('Click falling objects to send them back up!', 0, 350, windowWidth, 'center')
        love.graphics.printf('Snail powerup reduces object size and speed', 0, 380, windowWidth, 'center')
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    elseif gameState == 'play' then
        -- Draw background clouds first (behind everything)
        if backgroundClouds then
            love.graphics.setColor(1, 1, 1, 0.7) -- Semi-transparent clouds
            love.graphics.draw(backgroundClouds, 0, 0, 0, windowWidth / backgroundClouds:getWidth(), windowHeight / backgroundClouds:getHeight())
            love.graphics.setColor(1, 1, 1, 1) -- Reset color
        end
        
        -- Draw powerup if active
        if powerup.active then
            love.graphics.setColor(powerup.color[1], powerup.color[2], powerup.color[3], powerup.color[4])
            love.graphics.rectangle('fill', powerup.x, powerup.y, powerup.size, powerup.size)
            love.graphics.setColor(1, 1, 1, 1)
            -- Draw powerup icon
            if powerupIcon then
                local iconSize = powerup.size * 0.6 -- Make icon slightly smaller than the background
                local iconX = powerup.x + (powerup.size - iconSize) / 2
                local iconY = powerup.y + (powerup.size - iconSize) / 2
                love.graphics.draw(powerupIcon, iconX, iconY, 0, iconSize / powerupIcon:getWidth(), iconSize / powerupIcon:getHeight())
            else
                -- Fallback to text if image not found
                love.graphics.setFont(love.graphics.newFont(16))
                love.graphics.print('P', powerup.x + 15, powerup.y + 10)
            end
        end
        
        for _, obj in ipairs(fallingObjects) do
            if obj.img then
                love.graphics.draw(obj.img, obj.x, obj.y, 0, obj.size / obj.originalSize, obj.size / obj.originalSize)
            else
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle('fill', obj.x, obj.y, obj.size, obj.size)
                love.graphics.setColor(1, 1, 1)
            end
        end
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print('Score: ' .. score, 10, 10)
        love.graphics.print('Difficulty: ' .. math.floor(baseSpeedMultiplier * 100) .. '%', 10, 35)
        
        -- Show powerup status
        if powerupActive then
            local remainingTime = math.ceil(powerupDuration - powerupTimer)
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.print('POWERUP: ' .. remainingTime .. 's', 10, 60)
            love.graphics.setColor(1, 1, 1, 1)
        end
    elseif gameState == 'gameover' then
        -- Draw solid sky background for gameover screen
        if backgroundSolidSky then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(backgroundSolidSky, 0, 0, 0, windowWidth / backgroundSolidSky:getWidth(), windowHeight / backgroundSolidSky:getHeight())
        end
        
        love.graphics.setColor(0, 0, 0, 1) -- Set text color to black
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.printf('Game Over', 0, 200, windowWidth, 'center')
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf('Score: ' .. score, 0, 260, windowWidth, 'center')
        love.graphics.printf('Final Difficulty: ' .. math.floor(baseSpeedMultiplier * 100) .. '%', 0, 290, windowWidth, 'center')
        love.graphics.printf('Click to return to Title', 0, 350, windowWidth, 'center')
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    end
end

--This gives us highlighting of error issues along with our breakpoints
local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end 