local mode = {}

function mode:enter(from,data)

   self.child = data.child
   self.pointerID = (data.pointerID)
   self.start_time = love.timer.getTime()
end

function mode:pointermoved(x,y,dx,dy)

   if self.child.world_trans then
      --print("do yo thing mofo!")
      local x,y = self.child.parent.world_trans(dx,dy)
      local x2,y2 = self.child.parent.world_trans(0,0)

--      print(dx,x-x2,dy,y-y2)
      dx = x-x2
      dy = y-y2

      --print(x2-x,y2-y, dx,dy,"->",x,y,"->",self.child.pos.x,self.child.pos.y)
   end


   self.child.pos.x =    self.child.pos.x + dx--(dx/camera.scale)
   self.child.pos.y =    self.child.pos.y + dy--(dy/camera.scale)
   self.child.dirty = true
   --print(self.child.type, "dragging", self.child.pos.x, self.child.pos.y)
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
