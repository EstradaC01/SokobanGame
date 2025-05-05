local TILE_SIZE = 32

-- Game states
local STATE_MENU = "menu"
local STATE_PLAYING = "playing"
local STATE_WIN = "win"
local currentGameState = STATE_MENU

-- Menu options
local menuOptions = { "Start", "Exit" }
local selectedMenuIndex = 1

-- Tile constants
local TILE_WALL            = '#'
local TILE_FLOOR           = ' '
local TILE_GOAL            = '.'
local TILE_BOX             = '$'
local TILE_BOX_ON_GOAL     = '*'
local TILE_PLAYER          = '@'
local TILE_PLAYER_ON_GOAL  = '+'

-- Level layout
local levelData = {
    "########",
    "#  .   #",
    "#  $   #",
    "#  @   #",
    "########"
}

local gameMap = {}
local playerPosition = { x = 0, y = 0 }
local winTimer = 0

function love.load()
    love.window.setTitle("Sokoban in LOVE")
    love.window.setMode(#levelData[1] * TILE_SIZE, #levelData * TILE_SIZE)
    love.graphics.setFont(love.graphics.newFont(24))
end

function loadLevel()
    gameMap = {}
    for row = 1, #levelData do
        gameMap[row] = {}
        for col = 1, #levelData[row] do
            local tileChar = levelData[row]:sub(col, col)
            gameMap[row][col] = tileChar
            if tileChar == TILE_PLAYER or tileChar == TILE_PLAYER_ON_GOAL then
                playerPosition.x = col
                playerPosition.y = row
            end
        end
    end
end

function tryMovePlayer(dx, dy)
    local fromX, fromY = playerPosition.x, playerPosition.y
    local toX, toY = fromX + dx, fromY + dy
    local beyondX, beyondY = toX + dx, toY + dy

    local fromTile = gameMap[fromY][fromX]
    local toTile = gameMap[toY][toX]
    local beyondTile = gameMap[beyondY] and gameMap[beyondY][beyondX]

    if toTile == TILE_WALL then return end

    if toTile == TILE_BOX or toTile == TILE_BOX_ON_GOAL then
        if beyondTile == TILE_FLOOR or beyondTile == TILE_GOAL then
            gameMap[beyondY][beyondX] = (beyondTile == TILE_GOAL) and TILE_BOX_ON_GOAL or TILE_BOX
            gameMap[toY][toX] = (toTile == TILE_BOX_ON_GOAL) and TILE_GOAL or TILE_FLOOR
        else
            return
        end
    end

    gameMap[fromY][fromX] = (fromTile == TILE_PLAYER_ON_GOAL) and TILE_GOAL or TILE_FLOOR
    gameMap[toY][toX] = (toTile == TILE_GOAL) and TILE_PLAYER_ON_GOAL or TILE_PLAYER
    playerPosition.x, playerPosition.y = toX, toY

    if checkWinCondition() then
        currentGameState = STATE_WIN
        winTimer = 2 -- 2 seconds before returning to menu
    end
end

function checkWinCondition()
    for row = 1, #gameMap do
        for col = 1, #gameMap[row] do
            local tile = gameMap[row][col]
            if tile == TILE_GOAL or tile == TILE_PLAYER_ON_GOAL then
                return false
            end
        end
    end
    return true
end

function love.keypressed(key)
    if currentGameState == STATE_MENU then
        if key == "up" then
            selectedMenuIndex = (selectedMenuIndex - 1 < 1) and #menuOptions or selectedMenuIndex - 1
        elseif key == "down" then
            selectedMenuIndex = (selectedMenuIndex % #menuOptions) + 1
        elseif key == "return" then
            if menuOptions[selectedMenuIndex] == "Start" then
                currentGameState = STATE_PLAYING
                loadLevel()
            elseif menuOptions[selectedMenuIndex] == "Exit" then
                love.event.quit()
            end
        end
    elseif currentGameState == STATE_PLAYING then
        if key == "up" then tryMovePlayer(0, -1)
        elseif key == "down" then tryMovePlayer(0, 1)
        elseif key == "left" then tryMovePlayer(-1, 0)
        elseif key == "right" then tryMovePlayer(1, 0)
        elseif key == "r" then loadLevel()
        elseif key == "escape" then
            currentGameState = STATE_MENU
        end
    elseif currentGameState == STATE_WIN then
        if key == "return" or key == "escape" then
            currentGameState = STATE_MENU
        end
    end
end

function love.update(dt)
    if currentGameState == STATE_WIN then
        winTimer = winTimer - dt
        if winTimer <= 0 then
            currentGameState = STATE_MENU
        end
    end
end

function love.draw()
    if currentGameState == STATE_MENU then
        drawMainMenu()
    elseif currentGameState == STATE_PLAYING then
        drawGameWorld()
    elseif currentGameState == STATE_WIN then
        drawGameWorld()
        drawWinMessage()
    end
end

function drawMainMenu()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    for i, option in ipairs(menuOptions) do
        if i == selectedMenuIndex then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.printf(option, 0, screenHeight / 2 + (i - 1) * 40, screenWidth, "center")
    end
end

function drawGameWorld()
    for row = 1, #gameMap do
        for col = 1, #gameMap[row] do
            local tile = gameMap[row][col]
            local posX = (col - 1) * TILE_SIZE
            local posY = (row - 1) * TILE_SIZE

            -- Base background
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.rectangle("fill", posX, posY, TILE_SIZE, TILE_SIZE)

            if tile == TILE_WALL then
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", posX, posY, TILE_SIZE, TILE_SIZE)
            elseif tile == TILE_GOAL then
                love.graphics.setColor(0.6, 1.0, 0.6)
                love.graphics.rectangle("fill", posX, posY, TILE_SIZE, TILE_SIZE)
            elseif tile == TILE_BOX or tile == TILE_BOX_ON_GOAL then
                love.graphics.setColor(0.6, 0.4, 0.1)
                love.graphics.rectangle("fill", posX, posY, TILE_SIZE, TILE_SIZE)
                love.graphics.setColor(0, 0, 0) -- black X
                love.graphics.line(posX, posY, posX + TILE_SIZE, posY + TILE_SIZE)
                love.graphics.line(posX + TILE_SIZE, posY, posX, posY + TILE_SIZE)
            end

            if tile == TILE_PLAYER or tile == TILE_PLAYER_ON_GOAL then
                love.graphics.setColor(0.2, 0.6, 1.0)
                local centerX = posX + TILE_SIZE / 2
                local centerY = posY + TILE_SIZE / 2
                local radius = TILE_SIZE / 2.5
                love.graphics.circle("fill", centerX, centerY, radius)
            end

            -- Grid outline
            love.graphics.setColor(0, 0, 0, 0.2)
            love.graphics.rectangle("line", posX, posY, TILE_SIZE, TILE_SIZE)
        end
    end
end

function drawWinMessage()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, screenHeight / 2 - 40, screenWidth, 80)
    love.graphics.setColor(1, 1, 0)
    love.graphics.printf("Level Finished!", 0, screenHeight / 2 - 20, screenWidth, "center")
end
