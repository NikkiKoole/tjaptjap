local mode = {}

local utils = require "utils"

function mode:enter(from,data)
   self.child = data
   self.setPivot = false
end

function getXValueOfParent(obj,  parentId)
   local result = 0
   if (obj.id == parentId) then
      print(obj.id, parentId)
      result = obj.world_pos.x
      return result
   else
      if obj.parent then
         result = getXValueOfParent(obj.parent, parentId)
      end
   end
   return result
end
function getYValueOfParent(obj,  parentId)
   local result =0

   if (obj.id == parentId) then
      print(obj.id, parentId)
      result = obj.world_pos.y
      return result
   else
      if obj.parent then
         result = getYValueOfParent(obj.parent, parentId)
      end
   end
   return result
end
function getWorldTransform(obj, id)
   if obj.id == id then
      return obj.world_trans
   else
      if obj.parent then
         return getWorldTransform(obj.parent)
      else
         print("PROBLEMS!")
      end

      return 0
   end

end


function mode:update(dt)

   Hammer:reset(10,200)
   -- local n = Hammer:labelbutton("next click = set pivot", 120,40)


   -- if n.released then
   --    self.setPivot = true

   --    print("set pivot = ", self.setPivot)
   -- end

   Hammer:pos(0,0)
   local child = self.child
   local wx,wy = self.child.world_trans(child.data.w/2,0)

   --local rx1, ry1 = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.w/2, child.pos.y, child.pos.x, child.pos.y, child.rotation))
   --local rx1, ry1 = camera:cameraCoords(wx,wy)
   local p = self.child.pivot

   local rx1, ry1 = camera:cameraCoords(  self.child.world_trans(  (p and p.x or 0)+ child.data.w/2,  (p and p.y or 0))  )
   local rx2, ry2 = camera:cameraCoords(self.child.world_trans(p and p.x or 0, p and p.y or 0))

   local pivot = Hammer:rectangle( "pivot", 30, 30,{x=rx2-15, y=ry2-15, color=color})
   if pivot.startpress then
      print("start press")
   end

   if pivot.dragging then
      local p = getWithID(Hammer.pointers.moved, pivot.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then


         local wx,wy = self.child.world_trans(0,0)
         local wxr,wyr = camera:worldCoords(moved.x-pivot.dx, moved.y-pivot.dy)


         local a = getWorldTransform(self.child, "opa")
         print(a)
--         print(wx,wxr)
         --wxr = wxr - wx
         --wyr = wyr - wy

         --wxr,wyr = camera:worldCoords(moved.x, moved.y)

         --wxr,wyr = utils.rotatePoint(wxr, wyr, 0, 0, -self.child.world_pos.rot)

         if not self.child.pivot then
            self.child.pivot = {x=0,y=0}
         end
         --print(wxr, wyr)

         local xx2,yy2 = getWorldTransform(self.child, "opa")(0,0)
         --local xx2 = getXValueOfParent(self.child,'opa')
         --local yy2 = getYValueOfParent(self.child,'opa')
         print("stuff", xx2,yy2)
         local wxr2,wyr2 = camera:worldCoords(xx2, yy2)
         --local kkx,kky = camera:worldCoords(xx2,yy2)
         --local kxr,kyr = utils.rotatePoint(xx2, yy2, 0, 0, -self.child.world_pos.rot)
         --local kx2,ky2 = utils.rotatePoint(xx2, yy2, 0, 0, -self.child.world_pos.rot)
         --print(xx2, yy2)
         self.child.pivot.x = wxr - xx2 -- - xx2

--self.child.pos.x
         self.child.pivot.y = wyr - yy2-- - getYValueOfParent(self.child,'opa')
      end

   end



   local rotator = Hammer:rectangle( "rotator", 30, 30,{x=rx1-15, y=ry1-15, color=color})
   if rotator.dragging then
      local p = getWithID(Hammer.pointers.moved, rotator.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then
         --local wxr,wyr = camera:worldCoords(moved.x-rotator.dx, moved.y-rotator.dy)
         --local wx0, wy0 = self.child.world_trans(0, 0)
         --self.child.rotation = math.atan2(wyr - wy0, wxr - wx0)

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
      local isDirty = false
      for i=1, #Hammer.drawables do
         local it = Hammer.drawables[i]
         if it.over or it.pressed or it.dragging then
            isDirty = true
         end
      end

      -- if self.setPivot  and not isDirty then
      --    print("ok here i go!")
      --    local pressed = Hammer.pointers.pressed[1]
      --    print(pressed.x, pressed.y)


      --    local wx,wy = self.child.world_trans(0,0)
      --    local wxr,wyr = camera:worldCoords(pressed.x, pressed.y)
      --    --wxr,wyr = camera:worldCoords(moved.x, moved.y)
      --    wxr,wyr = utils.rotatePoint(wxr, wyr, 0, 0, -self.child.world_pos.rot)

      --    if not self.child.pivot then
      --       self.child.pivot = {x=0,y=0}
      --    end

      --    self.child.pivot.x = wxr-wx
      --    self.child.pivot.y = wyr-wy


      --    self.setPivot=false
      --    isDirty = true
      -- end




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
