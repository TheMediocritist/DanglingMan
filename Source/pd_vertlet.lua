import 'coreLibs/object'
import 'coreLibs/graphics'

local gravity           = 450
local physics_accuracy  = 3 -- how many passes should the constraint solver do? 1 is fine but stretchy.
local sqrt = math.sqrt
local mouse_influence   = 20
local mouse_cut         = 10
local screen_height     = 240
local screen_width      = 400
local accel_threshold   = 0.01
local accel_multiplier  = 100
local gfx = playdate.graphics

class('Constraint').extends()

function Constraint:init(p1, p2, spacing, tear_distance)
  self.p1 = p1
  self.p2 = p2
  self.length = spacing
  self.tear_distance = tear_distance
end

function Constraint:solve()
  local diff_x = self.p1.x - self.p2.x
  local diff_y = self.p1.y - self.p2.y
  local dist = sqrt(diff_x * diff_x + diff_y * diff_y)
  local diff = (self.length - dist) / dist

  if dist > self.tear_distance then
	self.p1:remove_constraint(self)
  end

  local scalar_1 = (1 / self.p1.mass) / ((1 / self.p1.mass) + (1 / self.p2.mass))
  local scalar_2 = 1 - scalar_1

  self.p1.x = self.p1.x + diff_x * scalar_1 * diff
  self.p1.y = self.p1.y + diff_y * scalar_1 * diff

  self.p2.x = self.p2.x - diff_x * scalar_2 * diff
  self.p2.y = self.p2.y - diff_y * scalar_2 * diff
end


function Constraint:draw()
  gfx.setLineWidth(2)
  gfx.drawLine(self.p1.x, self.p1.y, self.p2.x, self.p2.y)
end


class('Point').extends()

function Point:init(x, y)
  self.x = x
  self.y = y
  self.px = x
  self.py = y
  self.ax = 0
  self.ay = 0
  self.mass = 1
  self.constraints = {}
  self.pinned = false
  self.pin_x = nil
  self.pin_y = nil
end

function Point:update(dt)
  self:add_force(0, self.mass * gravity)
  local vx = self.x - self.px
  local vy = self.y - self.py
  local delta = dt * dt

  local nx = self.x + 0.99 * vx + 0.5 * self.ax * delta
  local ny = self.y + 0.99 * vy + 0.5 * self.ay * delta

  self.px = self.x
  self.py = self.y

  self.x = nx
  self.y = ny

  self.ax = 0
  self.ay = 0
end

function Point:update_accelerometer(calibrated_accelerometer)
  current_accelerometer = {playdate.readAccelerometer()}
  x_force = calibrated_accelerometer[1] - current_accelerometer[1]
  y_force = calibrated_accelerometer[2] - current_accelerometer[2]
  
  if math.abs(x_force) > accel_threshold or math.abs(y_force) > accel_threshold then
	  self:add_force(-x_force * accel_multiplier, -y_force * accel_multiplier/2)
  end
  
  --calibrated_accelerometer = current_accelerometer
end
  

function Point:draw()
  if #self.constraints == 0 then
	return
  end
  for index, constraint in ipairs(self.constraints) do
	constraint:draw()
  end
end

function Point:solve_constraints()
  for index, constraint in ipairs(self.constraints) do
	constraint:solve()
  end

  if self.y < 1 then
   self.y = 2 * (1) - self.y
  elseif self.y > screen_height then
	self.y = 2 * screen_height - self.y
  end

  if self.x > screen_width then
   self.x = 2 * screen_width - self.x

  elseif self.x < 1 then
	self.x = 2 * 1 - self.x
  end

  -- Pinning
  if self.pinned then
	self.x = self.pin_x
	self.y = self.pin_y
  end
end


function Point:attach(P, spacing, tear_distance)
  local constraint = Constraint(self, P, spacing, tear_distance)
  table.insert(self.constraints, constraint)
end

function Point:remove_constraint(lnk)
  for index, constraint in ipairs(self.constraints) do
	if constraint == lnk then
	  table.remove(self.constraints, index)
	  return
	end
  end
end

function Point:add_force(fx, fy)
  self.ax = self.ax + fx / self.mass
  self.ay = self.ay + fy / self.mass
end

function Point:pin(px, py)
  self.pinned = true
  self.pin_x = px
  self.pin_y = py
end


class('Physics').extends()

function Physics:init(points)
  self.points = points
  self.delta_sec = 16 / 1000;
  self.accuracy = physics_accuracy
end

function Physics:update(dt)
  for i = self.accuracy, 0, -1 do
	for index, point in ipairs(self.points) do
	  point:update_accelerometer(calibrated_accelerometer)
	  point:solve_constraints()
	end
  end


  for index, point in ipairs(self.points) do
	point:update(dt)
  end
end