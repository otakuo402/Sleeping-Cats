-- Player in the game's data

Player = Class{}

local WALKING_SPEED = 120
local JUMP_VELOCITY = 320

function Player:init(map)

  self.win = false
  self.x = 0
  self.y = 0
  self.width = 16
  self.height = 30
  self.timer = 0
  self.enemy = false
  self.timerEnemy = 0
  self.LevelTitleTimer = 0

  -- offset from top left to center to support sprite flipping
  self.xOffset = self.width / 2
  self.yOffset = self.height / 2

  -- reference to map for checking tiles
  self.map = map
  self.texture = love.graphics.newImage('graphics/Orange_Cat.png')

  -- sound effects
  self.sounds = {
      ['jump'] = love.audio.newSource('sounds/empty-block.wav', 'static'),
      ['statue'] = love.audio.newSource('sounds/powerup-reveal.wav', 'static'),
      ['death'] = love.audio.newSource('sounds/death.wav', 'static'),
      ['cat'] = love.audio.newSource('sounds/pickup.wav', 'static'),
      ['enemy'] = love.audio.newSource('sounds/kill2.wav', 'static')
  }
  -- animation frames
  self.frames = {}

  -- current animation frame
  self.currentFrame = nil

  -- used to determine behavior and animations
  self.state = 'idle'

  -- determines sprite flipping
  self.direction = 'left'

  -- x and y velocity
  self.dx = 0
  self.dy = 0

  -- position on top of map tiles
  self.y = map.tileHeight * ((map.mapHeight - 2) / 2) - self.height
  self.x = map.tileWidth * 10

  -- initialize all player animations
  self.animations = {
      ['idle'] = Animation({
          texture = self.texture,
          frames = {
              love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(64, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
          },
          interval = 0.1
      }),
      ['walking'] = Animation({
          texture = self.texture,
          frames = {
              love.graphics.newQuad(16, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(48, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(32, 0, self.width, self.height, self.texture:getDimensions()),
              love.graphics.newQuad(48, 0, self.width, self.height, self.texture:getDimensions()),
          },
          interval = 0.15
      }),
      ['jumping'] = Animation({
          texture = self.texture,
          frames = {
              love.graphics.newQuad(16, 0, self.width, self.height, self.texture:getDimensions())
          }
      }),
      ['dying'] = Animation({
          texture = self.texture,
          frames = {
              love.graphics.newQuad(80, 0, self.width, self.height, self.texture:getDimensions())
        }
      })
  }

  -- initialize animation and current frame we should render
  self.animation = self.animations['idle']
  self.currentFrame = self.animation:getCurrentFrame()

  -- behavior map we can call based on player state
  self.behaviors = {
      ['idle'] = function(dt)

          -- add spacebar functionality to trigger jump state
          if love.keyboard.wasPressed('w') and Freeze == false then
              self.dy = -JUMP_VELOCITY
              self.state = 'jumping'
              self.animation = self.animations['jumping']
              self.sounds['jump']:setVolume(0.5)
              self.sounds['jump']:play()
          elseif love.keyboard.isDown('a') and Freeze == false then
              self.direction = 'left'
              self.dx = -WALKING_SPEED
              self.state = 'walking'
              self.animations['walking']:restart()
              self.animation = self.animations['walking']
          elseif love.keyboard.isDown('d') and Freeze == false then
              self.direction = 'right'
              self.dx = WALKING_SPEED
              self.state = 'walking'
              self.animations['walking']:restart()
              self.animation = self.animations['walking']
          else
              self.dx = 0
          end
      end,
      ['walking'] = function(dt)

          -- keep track of input to switch movement while walking, or reset
          -- to idle if we're not moving
          if love.keyboard.wasPressed('w') and Freeze == false then
              self.dy = -JUMP_VELOCITY
              self.state = 'jumping'
              self.animation = self.animations['jumping']
              self.sounds['jump']:play()
          elseif love.keyboard.isDown('a') and Freeze == false then
              self.direction = 'left'
              self.dx = -WALKING_SPEED
          elseif love.keyboard.isDown('d') and Freeze == false then
              self.direction = 'right'
              self.dx = WALKING_SPEED
          else
              self.dx = 0
              self.state = 'idle'
              self.animation = self.animations['idle']
          end

          -- check for collisions moving left and right
          self:checkRightCollision()
          self:checkLeftCollision()

          -- check if there's a tile directly beneath us
          if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
              not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

              -- if so, reset velocity and position and change state
              self.state = 'jumping'
              self.animation = self.animations['jumping']
          end
      end,
      ['jumping'] = function(dt)
          -- die if go off them map somehow
          if self.y > 300 or self.x > map.mapWidth * 16 then
            self.sounds['death']:play()
            self.y = map.tileHeight * ((map.mapHeight - 2) / 2) - self.height
            self.x = map.tileWidth * 10
          end

          --die if go off map left
          if self.x < 0 then
            self.sounds['death']:play()
            self.y = map.tileHeight * ((map.mapHeight - 2) / 2) - self.height
            self.x = map.tileWidth * 10
          end

          if love.keyboard.isDown('a') and Freeze == false then
              self.direction = 'left'
              self.dx = -WALKING_SPEED
          elseif love.keyboard.isDown('d') and Freeze == false then
              self.direction = 'right'
              self.dx = WALKING_SPEED
          end

          -- apply map's gravity before y velocity
          self.dy = self.dy + self.map.gravity

          -- check if there's a tile directly beneath us
          if self.map:collides(self.map:tileAt(self.x + self.width / 4, self.y + self.height)) or
              self.map:collides(self.map:tileAt(self.x + self.width - 1 - self.width / 4, self.y + self.height)) then

              -- if so, reset velocity and position and change state
              self.dy = 0
              self.state = 'idle'
              self.animation = self.animations['idle']
              self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
          end

          -- check for collisions moving left and right
          self:checkRightCollision()
          self:checkLeftCollision()
      end,
      ['dying'] = function(dt)
          self.sounds['death']:play()
          --Messiah Cat Patch
          self.dy = 0

          self.y = map.tileHeight * ((map.mapHeight - 2) / 2) - self.height
          self.x = map.tileWidth * 10
          self.state = 'idle'
          self.animation = self.animations['idle']
      end
  }
end

function Player:update(dt)
  self.behaviors[self.state](dt)
  self.animation:update(dt)
  self.currentFrame = self.animation:getCurrentFrame()
  self.x = self.x + self.dx * dt

  self:calculateJumps()

  -- apply velocity
  self.y = self.y + self.dy * dt
end

-- jumping and block hitting logic
function Player:calculateJumps()

    -- cat statue collision
    if (self.map:tileAt(self.x, self.y)).id == (CAT_STATUE_BOTTOM) then
        self.mapTile(math.floor(self.x / self.map.tileWidth) + 1,
        math.floor(self.y / self.map.tileHeight) + 1, CAT_STATUE_BOTTOM_LIT)
        if self.win == false then
            self.sounds['statue']:play()
        end
        self.win = true
    end
    if self.map:tileAt(self.x + self.width, self.y).id == (CAT_STATUE_BOTTOM) then
      self.map:setTile(math.floor((self.x + self.width) / self.map.tileWidth) + 1,
          math.floor(self.y / self.map.tileHeight) + 1, CAT_STATUE_BOTTOM_LIT)
          if self.win == false then
              self.sounds['statue']:play()
          end
          self.win = true
    end
    if self.map:tileAt(self.x, self.y + self.height - 1).id == (CAT_STATUE_BOTTOM) then
        self.map:setTile(math.floor(self.x / self.map.tileWidth) + 1,
              math.floor((self.y + self.height - 1) / self.map.tileHeight) + 1, CAT_STATUE_BOTTOM_LIT)
              if self.win == false then
                  self.sounds['statue']:play()
              end
              self.win = true
    end
    if self.map:tileAt(self.x + self.width, self.y + self.height - 1).id == (CAT_STATUE_BOTTOM) then
        self.map:setTile(math.floor((self.x + self.width) / self.map.tileWidth) + 1,
            math.floor((self.y + self.height - 1) / self.map.tileHeight) + 1, CAT_STATUE_BOTTOM_LIT)
            if self.win == false then
                self.sounds['statue']:play()
            end
            self.win = true
    end
    if self.map:tileAt(self.x + (self.width - 1) / 2, self.y + (self.height - 1) / 2).id == (CAT_STATUE_BOTTOM) then
        self.map:setTile(math.floor((self.x + (self.width - 1) / 2) / self.map.tileWidth) + 1,
            math.floor(((self.height - 1) / 2) / self.map.tileHeight) + 1, CAT_STATUE_BOTTOM_LIT)
            if self.win == false then
                self.sounds['statue']:play()
            end
            self.win = true
    end

    if self.win == true then
        Freeze = true
        self.timer = self.timer + 1
        if self.timer == 100 then
          if map.wakeCat == false then
            CatSleeps = CatSleeps + 1
          end
            love.audio.stop()
            map:init()
            self.LevelTitleTimer = 80
            LevelNumber = LevelNumber + 1
            self.y = map.tileHeight * ((map.mapHeight - 2) / 2) - self.height
            self.x = map.tileWidth * 10
            self.win = false
            self.timer = 0
            Freeze = false
        end
    end

    -- sleeping cat collision
    if (self.map:tileAt(self.x, self.y)).id == (CAT_SLEEP) then
        self.mapTile(math.floor(self.x / self.map.tileWidth) + 1,
        math.floor(self.y / self.map.tileHeight) + 1, CAT_STARTLED)
        self.sounds['cat']:play()
        map.wakeCat = true
    end
    if self.map:tileAt(self.x + self.width - 1, self.y).id == (CAT_SLEEP) then
      self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1,
          math.floor(self.y / self.map.tileHeight) + 1, CAT_STARTLED)
          self.sounds['cat']:play()
          map.wakeCat = true
    end
    if self.map:tileAt(self.x + self.width / 4, self.y + self.height - 1).id == (CAT_SLEEP) then
        self.map:setTile(math.floor((self.x + self.width / 4) / self.map.tileWidth) + 1,
              math.floor((self.y + self.height - 1) / self.map.tileHeight) + 1, CAT_STARTLED)
              self.sounds['cat']:play()
              map.wakeCat = true
    end
    if self.map:tileAt(self.x + self.width - 1 - self.width / 4, self.y + self.height - 1).id == (CAT_SLEEP) then
        self.map:setTile(math.floor((self.x + self.width - 1 - self.width / 4) / self.map.tileWidth) + 1,
            math.floor((self.y + self.height - 1) / self.map.tileHeight) + 1, CAT_STARTLED)
            self.sounds['cat']:play()
            map.wakeCat = true
    end
    if self.map:tileAt(self.x + (self.width - 1) / 2, self.y + (self.height - 1) / 2).id == (CAT_SLEEP) then
        self.map:setTile(math.floor((self.x + (self.width - 1) / 2) / self.map.tileWidth) + 1,
            math.floor(((self.height - 1) / 2) / self.map.tileHeight) + 1, CAT_STARTLED)
            self.sounds['cat']:play()
            map.wakeCat = true
    end

    -- enemy collision
    self.sounds['enemy']:setVolume(0.5)
    if (self.map:tileAt(self.x, self.y)).id == (ENEMY_BOTTOM) then
        if self.enemy == false then
            self.sounds['enemy']:play()
        end
        self.animation = self.animations['dying']
        self.enemy = true
    end
    if self.map:tileAt(self.x + self.width, self.y).id == (ENEMY_BOTTOM) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x, self.y + self.height - 1).id == (ENEMY_BOTTOM) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x + self.width, self.y + self.height - 1).id == (ENEMY_BOTTOM) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x + (self.width - 1) / 2, self.y + (self.height - 1) / 2).id == (ENEMY_BOTTOM) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if (self.map:tileAt(self.x, self.y)).id == (ENEMY_TOP) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
        self.animation = self.animations['dying']
        self.enemy = true
    end
    if self.map:tileAt(self.x + self.width, self.y).id == (ENEMY_TOP) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x + self.width / 4, self.y + self.height).id == (ENEMY_TOP) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x - 1 + self.width - self.width / 4, self.y + self.height).id == (ENEMY_TOP) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x + (self.width - 1) / 2, self.y + (self.height - 1) / 2).id == (ENEMY_TOP) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x + self.width, self.y + self.height / 2 + 3).id == (ENEMY_TOP) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end
    if self.map:tileAt(self.x + self.width, self.y + self.height / 2 + 3).id == (ENEMY_TOP) then
      if self.enemy == false then
          self.sounds['enemy']:play()
      end
      self.animation = self.animations['dying']
      self.enemy = true
    end

    if self.enemy then
      self.timerEnemy = self.timerEnemy + 1
      self.animation = self.animations['dying']
      Freeze = true
      if self.timerEnemy == 40 then
        self.state = 'dying'
        self.timerEnemy = 0
        self.enemy = false
        Freeze = false
      end
    end
end

-- checks two tiles to our left to see if a collision occurred
function Player:checkLeftCollision()
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then

            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
end

-- checks two tiles to our right to see if a collision occurred
function Player:checkRightCollision()
    if self.dx > 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then

            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end
end

function Player:render()
local scaleX

-- set negative x scale factor if facing left, which will flip the sprite
-- when applied
if self.direction == 'right' then
    scaleX = 1
else
    scaleX = -1
end

-- draw sprite with scale factor and offsets
love.graphics.draw(self.texture, self.currentFrame, math.floor(self.x + self.xOffset),
    math.floor(self.y + self.yOffset), 0, scaleX, 1, self.xOffset, self.yOffset)
end

function love.keyreleased(key)
    if key == 'a' then
        self.dx = 0
    elseif key == 'd' then
        self.dx = 0
    end
end
