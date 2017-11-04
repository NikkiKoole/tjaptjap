--local inspect = require "vendor.inspect"
local mode = {}

function mode:enter(from,data)
   self.child = data
   self.start_time = love.timer.getTime()
end

function mode:touchmoved( id, x, y, dx, dy, pressure )
   self.child.pos.x =    self.child.pos.x + (dx/camera.scale)
   self.child.pos.y =    self.child.pos.y + (dy/camera.scale)
   self.child.dirty = true
end

function mode:touchreleased( id, x, y, dx, dy, pressure )
   local current_time = love.timer.getTime()
   if (current_time - self.start_time) > 0.2 then
      Signal.emit("switch-state", "stage")
   else
      Signal.emit("switch-state", "edit-item", self.child)
   end

end

return mode
