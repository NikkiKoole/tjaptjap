local mode = {}
local a = require "vendor.affine"
local utils = require "utils"

function mode:enter(from,data)
   data.dirty_types = {}
   self.child = data
   self.setPivot = false
end

function mode:update(dt)
   self.child.dirty_types = {}
   Hammer:reset(10,200)
   local n = Hammer:labelbutton("next click = set pivot", 120,40)

   if n.released then
      self.setPivot = true
   end
   Hammer:pos(0,0)
   local child = self.child
   local wx,wy = self.child.world_trans(child.data.w/2,0)
   local p = child.pivot
   local pivot_x, pivot_y = camera:cameraCoords( child.world_trans(p and p.x or 0, p and p.y or 0))
   local pivot = Hammer:rectangle( "pivot", 30, 30,{x=pivot_x-15, y=pivot_y-15, color=color})
   if pivot.dragging then
      local p = getWithID(Hammer.pointers.moved, pivot.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then
         local wx,wy = camera:worldCoords(moved.x-pivot.dx, moved.y-pivot.dy)
         wx,wy = child.inverse(wx,wy)
         if not child.pivot then
            child.pivot = {x=0,y=0}
         end

         local dx = wx - child.pivot.x
         local dy = wy - child.pivot.y

         child.pivot.x = wx
         child.pivot.y = wy
         local sx = child.scale and child.scale.x or 1
         local sy = child.scale and child.scale.y or 1
         local t2x, t2y = utils.rotatePoint(dx*sx, dy*sy, 0, 0, child.rotation)

         child.pos.x = child.pos.x + t2x
         child.pos.y = child.pos.y + t2y
         child.dirty = true
         table.insert(child.dirty_types, "pivot")
         table.insert(child.dirty_types, "pos")

      end
   end



   local rx1, ry1 = camera:cameraCoords( child.world_trans(  (p and p.x or 0) + (child.data.w/2 ) ,  (p and p.y or 0))  )

   local rotator = Hammer:rectangle( "rotator", 30, 30,{x=rx1-15, y=ry1-15, color=color})
   if rotator.dragging then
      local p = getWithID(Hammer.pointers.moved, rotator.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then
         self.child.rotation = math.atan2((moved.y-rotator.dy) - pivot_y, (moved.x-rotator.dx) - pivot_x)
         if self.child.parent then
            if self.child.parent.world_pos.rot then
               self.child.rotation = self.child.rotation - self.child.parent.world_pos.rot
            end
         end

         table.insert(child.dirty_types, "rotation")
         self.child.dirty = true
      end
   end

   local rescaler_x, rescaler_y = camera:cameraCoords(  child.world_trans(  ( 0) + (child.data.w/2) ,  (0) + (child.data.h/2))  )
   local rescaler = Hammer:rectangle( "rescaler", 30, 30,{x=rescaler_x-15, y=rescaler_y-15, color=color})
   if rescaler.dragging then
      local p = getWithID(Hammer.pointers.moved, rescaler.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then
         local wx,wy = camera:worldCoords(moved.x-rescaler.dx, moved.y-rescaler.dy)
         wx,wy = child.inverse(wx,wy)
         wx,wy = wx+self.child.data.w/2, wy+self.child.data.h/2
         local sx = child.scale and child.scale.x or 1
         local sy = child.scale and child.scale.y or 1
         local t2x, t2y = utils.rotatePoint((wx/child.data.w)*sx,
                                            (wy/child.data.h)*sy, 0, 0, 0)

         -- to keep aspect ratio
         t2x,t2y = math.min(t2x,t2y),math.min(t2x,t2y)
         self.child.scale = {x=t2x, y=t2y}
         table.insert(child.dirty_types, "scale")
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
