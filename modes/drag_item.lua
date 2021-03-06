local mode = {}
local utils = require "utils"

function mode:enter(from,data)
   self.child = data.child
   self.pointerID = (data.pointerID)
   self.start_time = love.timer.getTime()
end

function mode:pointermoved(x,y,dx,dy)
   if self.child.world_trans then
      if self.child.parent then
         local theta = self.child.parent.world_pos.rot
         dx,dy = utils.rotatePoint(dx,dy,0,0,-theta)
         dx = (dx/camera.scale) / self.child.parent.world_pos.scaleX
         dy = (dy/camera.scale) / self.child.parent.world_pos.scaleY
      end
   end
   self.child.pos.x =    self.child.pos.x + dx
   self.child.pos.y =    self.child.pos.y + dy
   self.child.dirty = true
end

function mode:mousemoved(x,y,dx,dy,istouch)
   if (not istouch) then
      self:pointermoved(x,y,dx,dy)
   end
end

function mode:touchmoved( id, x, y, dx, dy, pressure )
   if self.pointerID == id then --otherwise you can drag with multiple fingers
      self:pointermoved(x,y,dx,dy)
   end
end

function mode:pointerreleased()
   local current_time = love.timer.getTime()
   if (current_time - self.start_time) > 0.2 then
      Signal.emit("switch-state", "stage")
   else
      if (self.child.type == "polygon") then
         Signal.emit("switch-state", "edit-polygon", self.child)
      elseif (self.child.type == "rope") then
         Signal.emit("switch-state", "edit-rope", self.child)
      elseif (self.child.type == "polyline") then
         Signal.emit("switch-state", "edit-polyline", self.child)
      elseif (self.child.type == "mesh3d") then
         Signal.emit("switch-state", "edit-mesh3d", self.child)
      elseif (self.child.type == "simplerect") then
         Signal.emit("switch-state", "edit-rect", self.child)
      elseif (self.child.type == "smartline") then
         Signal.emit("switch-state", "edit-smartline", self.child)
      elseif (self.child.type == "star" or self.child.type == "rect" or self.child.type == "circle") then
         Signal.emit("switch-state", "edit-item", self.child)
      else
         print("drag_item: unhandled child type: ",self.child.type)
      end
   end
end

function mode:mousereleased(x,y,button, istouch)
   if (not istouch) then
      self:pointerreleased()
   end
end

function mode:touchreleased( id, x, y, dx, dy, pressure )
   self:pointerreleased()
end

return mode
