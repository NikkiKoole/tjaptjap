local mode = {}

local utils = require "utils"

function mode:enter(from,data)
   self.child = data
end

function mode:update(dt)
   Hammer:reset(0,0)

   local child = self.child
   local rx1, ry1 = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.w/2, child.pos.y, child.pos.x, child.pos.y, child.rotation))

   local rotator = Hammer:rectangle( "rotator", 30, 30,{x=rx1-15, y=ry1-15, color=color})
   if rotator.dragging then
      local p = getWithID(Hammer.pointers.moved, rotator.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then
         local wx,wy = camera:worldCoords(moved.x-rotator.dx, moved.y-rotator.dy)
         self.child.rotation = math.atan2(wy - child.pos.y, wx - child.pos.x)
         self.child.dirty = true
      end
   end



   -- if clicked outside any of the UI elements or the actual shape go back to the stage mode
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
