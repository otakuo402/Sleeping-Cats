-- renders tile map and handles tile data

require 'Util'

Map = Class{}

TILE_GRASS = 1
TILE_EMPTY = -1

-- cloud tiles
CLOUD_LEFT = 2
CLOUD_RIGHT = 3

-- grass tile
GRASS = 5

-- stone tile
STONE = 6

-- tree tile
TREE_TOP = 4
TREE_BOTTOM = 8

-- enemy tiles
ENEMY_TOP = 7
ENEMY_BOTTOM = 11

-- sleepy cat tiles
CAT_SLEEP = 9
CAT_STARTLED = 10

-- hill tiles
HILL_LEFT = 13
HILL_RIGHT = 14

-- cat statue tiles
CAT_STATUE_TOP = 12
CAT_STATUE_BOTTOM = 16
CAT_STATUE_BOTTOM_LIT = 15

-- speed of the screen scrolling
local SCROLL_SPEED = 62

-- map generator
function Map:init()

  self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
  self.sprites = generateQuads(self.spritesheet, 16, 16)
  self.music = love.audio.newSource('music/Forest.wav', 'static')

  self.tileWidth = 16
  self.tileHeight = 16
  self.mapWidth = 140
  self.mapHeight = 28
  self.tiles = {}
  self.wakeCat = false

  -- applies positive Y influence on anything affected
  self.gravity = 18

  -- associate player with map
  self.player = Player(self)

  -- camera offsets
  self.camX = 0
  self.camY = -3

  -- cache width and height of map in pixels
  self.mapWidthPixels = self.mapWidth * self.tileWidth
  self.mapHeightPixels = self.mapHeight * self.tileHeight

  -- fills map with empty tiles
  for y = 1, self.mapHeight do
      for x = 1, self.mapWidth do
          -- support for multiple sheets per tile; storing tiles as tables
          self:setTile(x, y, TILE_EMPTY)
      end
  end

  -- generates the cat statue at the end of the level
  local statueLevel = self.mapHeight / 2 - 1
  self:setTile(self.mapWidth - 1, statueLevel, CAT_STATUE_BOTTOM)
  self:setTile(self.mapWidth - 1, statueLevel - 1, CAT_STATUE_TOP)
  self:setTile(self.mapWidth, statueLevel, TILE_GRASS)
  self:setTile(self.mapWidth, statueLevel - 1, TILE_GRASS)
  for y = self.mapHeight / 2, self.mapHeight do
      self:setTile(self.mapWidth - 1, y, TILE_GRASS)
      self:setTile(self.mapWidth, y, TILE_GRASS)
      self:setTile(self.mapWidth - 2, y, TILE_GRASS)
      self:setTile(self.mapWidth - 3, y, TILE_GRASS)
  end

  -- begin generating the terrain using vertical scan lines
  local x = 1
  while x < self.mapWidth - 3 do

      -- 6.7% chance to generate a cloud
      if x < self.mapWidth - 2 then
          if math.random(60) == 1 then
              -- random height for cloud to generate above ground and other stuff
              local cloudStart = math.random(self.mapHeight / 2 - 5)
              self:setTile(x, cloudStart, CLOUD_LEFT)
              self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
          end
      end

      -- chance to generate a flat piece of ground
      if (math.random(30) == 1 and x < self.mapWidth - 1) or x == self.tileWidth * 10 then
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
        end
        x = x + 1

      -- 5% chance to generate a tree
    elseif math.random(120) == 1 and x < self.mapWidth - 1 then
          self:setTile(x, self.mapHeight / 2 - 2, TREE_TOP)
          self:setTile(x, self.mapHeight / 2 - 1, TREE_BOTTOM)
          for y = self.mapHeight / 2, self.mapHeight do
              self:setTile(x, y, TILE_GRASS)
          end
          x = x + 1

      -- 10% chance to generate grass
    elseif math.random(80) == 1 and x < self.mapWidth - 2 then
          self:setTile(x, self.mapHeight / 2 - 1, GRASS)
          for y = self.mapHeight / 2, self.mapHeight do
              self:setTile(x, y, TILE_GRASS)
          end
          x = x + 1

      -- 10% chance to generate a stone
    elseif math.random(80) == 1 then
        self:setTile(x, self.mapHeight / 2 - 1, STONE)
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
        end
        x = x + 1

    -- 5% chance to generate a sleepy cat
  elseif math.random(120) == 1 and x > 12 then
        self:setTile(x + 1, self.mapHeight / 2 - 1, CAT_SLEEP)
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
            self:setTile(x + 1, y, TILE_GRASS)
            self:setTile(x + 2, y, TILE_GRASS)
        end
        x = x + 3

    -- 20% chance to generate an enemy
  elseif math.random(60) == 1 and x < self.mapWidth - 5 then
      if x > 12 then
        self:setTile(x + 2, self.mapHeight / 2 - 1, ENEMY_BOTTOM)
        self:setTile(x + 2, self.mapHeight / 2 - 2, ENEMY_TOP)
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
            self:setTile(x + 1, y, TILE_GRASS)
            self:setTile(x + 2, y, TILE_GRASS)
            self:setTile(x + 3, y, TILE_GRASS)
            self:setTile(x + 4, y, TILE_GRASS)
        end
        x = x + 5
      else
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
        end
        x = x + 1
      end

    -- 10% chance of generating a hill
  elseif (math.random(180) == 1 and x < self.mapWidth - 12) then
      if x > 12 then
        self:setTile(x, self.mapHeight / 2 - 1, HILL_LEFT)
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
        end
        x = x + 1
        local HillSize = math.random(6, 1)
        for hill = 0, HillSize do
            self:setTile(x, self.mapHeight / 2 - 1, TILE_GRASS)
            if math.random(60) == 1 then
              self:setTile(x, self.mapHeight / 2 - 3, TREE_TOP)
              self:setTile(x, self.mapHeight / 2 - 2, TREE_BOTTOM)
            end
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_GRASS)
            end
            x = x + 1
        end
        self:setTile(x, self.mapHeight / 2 - 1, HILL_RIGHT)
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
        end
        x = x + 1
      end

    else
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(x, y, TILE_GRASS)
        end
    end
    -- start background music
    self.music:setLooping(true)
    self.music:play()
    Player.LevelTitleTimer = 80
  end
end

-- Tile collision
function Map:collides(tile)
    -- defining collidable tiles
    local collidables = {
      TILE_GRASS, HILL_LEFT, HILL_RIGHT, ENEMY_TOP,
      ENEMY_BOTTOM, CAT_STATUE_TOP, CAT_STATUE_BOTTOM, CAT_STATUE_BOTTOM_LIT
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end
    return false
end

-- function to update camera offset
function Map:update(dt)
    self.player:update(dt)

    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
  return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
  self.tiles[(y - 1) * self.mapWidth + x] = id
end

-- renders our map to the screen, to be called by main's render
function Map:render()
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    self.player:render()
end
