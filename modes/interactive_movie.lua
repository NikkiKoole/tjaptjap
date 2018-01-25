--[[

   This mode lets you drag items on stage and change its properties (rotation, scale, shape etc)
   You can also make a recording of such a session

   It does mean however that I'll need a lot of UI for all different types of items,
   Most of this ui and logic currently is buried in specific modes

   I suppose some generalist UI could come in handy too,
   like some moveable widgets to rotate or some slider to change props.

   You should be able to select multipe items and change both their properties at the same time

--]]

local mode = {}

function mode:enter()
   self.selectedItems = {}
end

function mode:update(dt)
   Hammer:reset(10, 100)

   local stage_mode = Hammer:labelbutton("stage mode", 130,40)
   if stage_mode.released then
      self.touches = {}
      Signal.emit("switch-state", "stage", {pointerID=id})
   end


end

function testHit(x,y, obj)
   local result = false
   local wx, wy = camera:worldCoords(x,y)

   if obj.triangles then
      if pointInPoly({x=wx,y=wy}, obj.triangles) then
         result = true
      end
   end
   if obj.children then
      for i,o in pairs(obj.children) do
         if testHit(x,y, o) then
            result = true
         end
      end
   end

   return result
end

function mode:pointermoved(id, x, y, dx, dy)
   -- find item
   local item
   for i,it in pairs(self.selectedItems) do
      if (it.id == id) then
         item = it.item
         break
      end
   end

   if item then
      item.pos.x = item.pos.x + dx/camera.scale
      item.pos.y = item.pos.y + dy/camera.scale
      item.dirty = true
   end

end

function mode:mousemoved(x, y, dx, dy, istouch)
   if not istouch then
      self:pointermoved("mouse",x,y,dx,dy)
   end
end

function mode:touchmoved( id, x, y, dx, dy, pressure )
      self:pointermoved(id,x,y,dx,dy)
end

function mode:pointerpressed(x, y, id)
   for i,o in pairs(world.children) do
      if testHit(x,y,o) then
         table.insert(self.selectedItems, {id=id, item=o})
         print("hit! "..o.type.." id:"..tostring(id))
      end
   end
end

function mode:pointerreleased(x,y,id)
   for i,it in pairs(self.selectedItems) do
      if (it.id == id) then
         table.remove(self.selectedItems, i)
      end
   end
end

function mode:mousepressed( x, y, button, istouch )
   if (not istouch) then
      self:pointerpressed(x, y, "mouse")
   end
end

function mode:touchpressed( id, x, y, dx, dy, pressure )
   self:pointerpressed(x, y, id)
end

function mode:mousereleased(x,y,button, istouch)
   if (not istouch) then
      self:pointerreleased(x,y,"mouse")
   end
end

function mode:touchreleased( id, x, y, dx, dy, pressure )
   self:pointerreleased(x,y,id)
end





return mode
