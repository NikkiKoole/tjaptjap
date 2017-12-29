local mode = {}

function mode:enter(from,data)

   self.child = data.child
   self.pointerID = (data.pointerID)
   self.start_time = love.timer.getTime()
end

function mode:pointermoved(x,y,dx,dy)
   self.child.pos.x =    self.child.pos.x + (dx/camera.scale)
   self.child.pos.y =    self.child.pos.y + (dy/camera.scale)
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
      else
         Signal.emit("switch-state", "edit-item", self.child)
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
