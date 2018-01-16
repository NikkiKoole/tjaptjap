local mode = {}
local a = require "vendor.affine"

local utils = require "utils"

function mode:enter(from,data)
   self.child = data
   self.setPivot = false
end



function mode:update(dt)

   Hammer:reset(10,200)
   local n = Hammer:labelbutton("next click = set pivot", 120,40)

   if n.released then
      self.setPivot = true
   end

   Hammer:pos(0,0)
   local child = self.child
   local wx,wy = self.child.world_trans(child.data.w/2,0)

   --local rx1, ry1 = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.w/2, child.pos.y, child.pos.x, child.pos.y, child.rotation))
   --local rx1, ry1 = camera:cameraCoords(wx,wy)
   local p = child.pivot
   local rx2, ry2 = camera:cameraCoords( child.world_trans(p and p.x or 0, p and p.y or 0))
   local pivot = Hammer:rectangle( "pivot", 30, 30,{x=rx2-15, y=ry2-15, color=color})
   local rx1, ry1 = camera:cameraCoords(  child.world_trans(  (p and p.x or 0) + (child.data.w/2) ,  (p and p.y or 0))  )
   --local rx1, ry1 = camera:cameraCoords(  child.world_trans( (child.data.w/2) , 0)  )

   local rotator = Hammer:rectangle( "rotator", 30, 30,{x=rx1-15, y=ry1-15, color=color})
   if rotator.dragging and not pivot.dragging then
      local p = getWithID(Hammer.pointers.moved, rotator.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then
         self.child.rotation = math.atan2((moved.y-rotator.dy) - ry2, (moved.x-rotator.dx) - rx2)

         if self.child.parent then
            if self.child.parent.world_pos.rot then
               self.child.rotation = self.child.rotation - self.child.parent.world_pos.rot
            end
         end

         self.child.dirty = true
      end
   end

   -- if clicked outside any of the UI elements or the actual shape go back to the stage mode
   if #Hammer.pointers.pressed == 1 then
      local isDirty = Hammer:isDirty()

      if self.setPivot  and not isDirty then
         setPivot(self)
         isDirty = true
      end


      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)
      local hit = pointInPoly({x=wx,y=wy}, self.child.triangles)
      if hit then
         isDirty = true
      end

      if not isDirty then
      -- if hit test children (if any) try and drag them
         if self.child.children then
            for i=1,#self.child.children do
               local hit = pointInPoly({x=wx,y=wy}, self.child.children[i].triangles)
               if hit then
                  Signal.emit("switch-state", "drag-item", {child=self.child.children[i], pointerID=Hammer.pointers.pressed[1].id})
                  isDirty=true
               end

            end
         end
      end
      if not isDirty then
         if self.child.parent and self.child.parent.id ~= "world" then
            Signal.emit("switch-state", "edit-rect", self.child.parent)
         else
            Signal.emit("switch-state", "stage")
         end
      end
   end


end


return mode
