local mode = {}

local pointdragging = {}
function getDraggingByPointerID(pointerID)
   for i=1, #pointdragging do
      if pointdragging[i].pointerID == pointerID then
         return pointdragging[i].draggingID
      end
   end
   return -1
end
function getIndexOfPointerID(pointerID)
   for i=1, #pointdragging do
      if pointdragging[i].pointerID == pointerID then
         return i
      end
   end
   return -1
end



function mode:enter(from,data)
   self.child = data
end

function mode:update(dt)
   local color={200,100,100}

   Hammer:reset(0,0)

   Hammer:rectangle( "resizer", 30, 30)
   local c = self.child
   local coords = c.data.coords
   for i=1, #coords, 2 do
      local rx,ry      = camera:cameraCoords(coords[i]   + c.pos.x,
                                             coords[i+1] + c.pos.y)
      local node = Hammer:rectangle( "node"..i, 30, 30,{x=rx-15, y=ry-15, color=color})

      if node.dragging then
         local p = getWithID(Hammer.pointers.moved, node.pointerID)
         local moved = Hammer.pointers.moved[p]
         if moved then
            local wx,wy = camera:worldCoords(moved.x - (node.dx),
                                             moved.y - (node.dy))
            self.child.data.coords[i]   = wx - c.pos.x
            self.child.data.coords[i+1] = wy - c.pos.y
            self.child.dirty = true
         end

      end
   end





   if #Hammer.pointers.pressed == 1 then
      local isDirty = false
      for i=1, #Hammer.drawables do
         local it = Hammer.drawables[i]
         if it.over or it.pressed or it.dragging then
            isDirty = true
         end
      end

      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)
      local hit = pointInPoly({x=wx,y=wy}, self.child.triangles)
      if hit then
         isDirty = true
      end

      if not isDirty then
         Signal.emit("switch-state", "stage")
      end
   end

end


return mode
