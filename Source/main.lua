import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "pd_vertlet"

local gfx = playdate.graphics
local gravity           = 450
local cloth_height      = 30
local cloth_width       = 1
local start_y           = 0
local spacing           = 7
local tear_distance     = 80
local rope_length       = 20

gfx.setColor(gfx.kColorBlack)

function build_rope()
  local points = {}
  local start_x = 200 -- love.graphics.getWidth()/2
  
  for y = 1, rope_length do
    local p = Point(start_x, start_y + (y * spacing) - spacing)
    
    if y ~= 1 then
      p:attach(points[(y-2) + 1], spacing, tear_distance)
    end
    
    if y == 1 then
      p:pin(p.x, p.y)
    end
    
    table.insert(points, p)
  end
  return points
end

function load()
  playdate.startAccelerometer()
  calibrated_accelerometer = {playdate.readAccelerometer()}
  print (calibrated_accelerometer[1], calibrated_accelerometer[2],calibrated_accelerometer[3])
  points = build_rope()
  once = true
  physics = Physics(points);

  imageTablePlayer = gfx.imagetable.new("diverDingus-table-32-32.png")
  imagePlayer = imageTablePlayer:getImage(2, 1)
  imageBackground = gfx.image.new("backgroundTest.png")
end

function clamp(low, n, high) 
  return math.min(math.max(n, low), high) 
end

load()

function get_delta_time(min, max)
  -- clamp to min & max to prevent simulator from doing weird stuff, eg. when it loses focus
  local delta_time = math.min(math.max(playdate.getElapsedTime(), min), max)
  playdate.resetElapsedTime()
  return delta_time
end

function playdate.update()
  -- Update dt
  dt = get_delta_time(0.01, 0.1)
  
  -- Get info from accelerometer and add force to the rope points
  physics:update(dt)
  
  -- put the dangling man on the end of the rope
  playerX, playerY = points[rope_length].x - 16, points[rope_length].y - 6
  
  -- Draw the rope & dangling man
  gfx.clear(gfx.kColorWhite)
  imageBackground:draw(0, 0)
  
  gfx.setColor(gfx.kColorBlack)
  
  for index, point in ipairs(points) do
    point:draw()
  end
  
  gfx.setColor(gfx.kColorWhite)
  imagePlayer:draw(playerX, playerY)
  playdate.drawFPS(0,0)

end

