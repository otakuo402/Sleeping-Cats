Class = require 'class'
push = require 'push'

require 'Animation'
require 'Map'
require 'Player'

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
LevelNumber = 1
CatSleeps = 0
Freeze = true
GameStart = false
LorePage = false
Menu = love.graphics.newImage('graphics/Menu.png')
Win = love.graphics.newImage('graphics/Win_Forest.png')

math.randomseed(os.time())

love.graphics.setDefaultFilter('nearest', 'nearest')

map = Map()

function love.load()
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true
    })

    love.window.setTitle('Sleeping Cats')

    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

-- called whenever window is resized
function love.resize(w, h)
    push:resize(w, h)
end

-- global key pressed function
function love.keyboard.wasPressed(key)
    if (love.keyboard.keysPressed[key]) then
        return true
    else
        return false
    end
end

-- global key released function
function love.keyboard.wasReleased(key)
    if (love.keyboard.keysReleased[key]) then
        return true
    else
        return false
    end
end

-- called whenever a key is pressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

-- called whenever a key is released
function love.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

-- called every frame, with dt passed in as delta in time since last frame
function love.update(dt)
    map:update(dt)

    -- reset all keys pressed and released this frame
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

-- called each frame, used to render to the screen
function love.draw()
    -- begin virtual resolution drawing
    push:apply('start')
    -- Main Menu
    if GameStart == false and LorePage == false then
      love.graphics.clear(51/255, 153/255, 255/255, 255/255)
      love.graphics.draw(Menu, 0, 0, 0, 0.25, 0.25)
      love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 32))
      love.graphics.printf('Sleeping Cats', 0, 60, VIRTUAL_WIDTH, 'center')
      love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 16))
      love.graphics.printf('Start', 0, 120, VIRTUAL_WIDTH, 'center')
      love.graphics.printf('Lore', 0, 140, VIRTUAL_WIDTH, 'center')
      love.graphics.printf('Exit', 0, 160, VIRTUAL_WIDTH, 'center')
      if love.mouse.isDown(1) then
          if love.mouse.getY() >= 360 and love.mouse.getY() <= 390 then
              if love.mouse.getX() >= 570 and love.mouse.getX() <= 700 then
                  GameStart = true
                  Freeze = false
              end
          elseif love.mouse.getY() >= 420 and love.mouse.getY() <= 450 then
              if love.mouse.getX() >= 586 and love.mouse.getX() <= 690 then
                  LorePage = true
              end
          elseif love.mouse.getY() >= 480 and love.mouse.getY() <= 510 then
            if love.mouse.getX() >= 600 and love.mouse.getX() <= 680 then
                love.event.quit()
            end
          end
      end
    elseif LorePage == true then
      love.graphics.clear(51/255, 153/255, 255/255, 255/255)
      love.graphics.draw(Menu, 0, 0, 0, 0.25, 0.25)
      love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 16))
      love.graphics.printf('back', 10, 200, VIRTUAL_WIDTH, 'left')
      love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 32))
      love.graphics.printf('Lore', 0, 60, VIRTUAL_WIDTH, 'center')
      love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 8))
      love.graphics.printf('You are traveling through the wilderness living your life\nwhen all of a sudden green tendrils sprout from the ground.\nThese tendrils grew into the form of sentinent poisonous\nplants that are making the rest of the cats fall asleep.\nComplete 10 levels without waking up the cats to complete the\ngame. WASD to move, touch the cat statue to complete levels.', 0, 95, VIRTUAL_WIDTH, 'center')
      love.graphics.draw(map.spritesheet, map.sprites[ENEMY_TOP], 200, 170, 0, 2, 2)
      love.graphics.draw(map.spritesheet, map.sprites[ENEMY_BOTTOM], 200, 202, 0, 2, 2)
      if love.mouse.isDown(1) then
          if love.mouse.getX() >= 30 and love.mouse.getX() <= 140 then
              if love.mouse.getY() >= 597 and love.mouse.getY() <= 630 then
                  LorePage = false
              end
          end
      end
      if love.keyboard.isDown('y') then
          GameStart = true
          LorePage = false
          CatSleeps = 10
          LevelNumber = 11
      end
    elseif CatSleeps < 10 then
        -- clear screen a background blue
        love.graphics.clear(51/255, 153/255, 255/255, 255/255)

        -- renders our map object onto the screen
        love.graphics.translate(math.floor(-map.camX + 0.5), math.floor(-map.camY + 0.5))
        map:render()

        -- renders the Level title
        if Player.LevelTitleTimer > 1 then
          Player.LevelTitleTimer = Player.LevelTitleTimer - 1
          love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 16))
          love.graphics.printf('Level ' .. tostring(LevelNumber), 0, 30, VIRTUAL_WIDTH, 'center')
        end

        -- renders number of levels completed where no cats were awoken
        love.graphics.draw(map.spritesheet, map.sprites[CAT_SLEEP], map.camX + 10, map.camY + 6)
        love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 16))
        love.graphics.printf('x ' .. tostring(CatSleeps), map.camX + 28, map.camY + 8, VIRTUAL_WIDTH, 'left')
    else
        Freeze = true
        love.graphics.clear(0/255, 77/255, 13/255, 255/255)
        love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 16))
        if LevelNumber < 11 then
            love.graphics.printf('Do not cheat, it is just a game', 0, 30, VIRTUAL_WIDTH, 'center')
        else
            love.graphics.draw(Win, 0, -100, 0, 1, 1)
            love.graphics.printf('You Win!', 0, 30, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('Levels Taken: ' .. tostring(LevelNumber - 1), 0, 60, VIRTUAL_WIDTH, 'center')
            love.graphics.draw(map.spritesheet, map.sprites[CAT_SLEEP], 180, 140, 0, 4, 4)
            love.graphics.printf('Back to Main Menu', 0, 100, VIRTUAL_WIDTH, 'center')
            if love.mouse.isDown(1) then
                if love.mouse.getX() >= 405 and love.mouse.getX() <= 870 then
                    if love.mouse.getY() >= 300 and love.mouse.getY() <= 332 then
                        GameStart = false
                        LevelNumber = 1
                        CatSleeps = 0
                    end
                end
            end
        end
    end

    -- end virtual resolution
    push:apply('end')
end
