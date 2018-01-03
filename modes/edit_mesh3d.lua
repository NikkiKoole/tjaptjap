local mode = {}
local utils = require "utils"

function mode:enter(from,data)
   self.child = data
end

function mode:update(dt)
   local color = {200,100,100}

   Hammer:reset(0,0)

   --print(self.child.data.width)
   --print(self.child.data.cells[1][1].x)
   local data = self.child.data
   --print(data.cx, data.cy)
   for i=1, data.width+1 do
      for j=1, data.height+1 do
         local rx,ry = camera:cameraCoords(data.cells[i][j].x +self.child.pos.x, data.cells[i][j].y+self.child.pos.y)
         local node = Hammer:rectangle( "n"..i..","..j, 30, 30,{x=rx,
                                                                y=ry,
                                                                color=color})
         if node.dragging then
            local p = getWithID(Hammer.pointers.moved, node.pointerID)
            local moved = Hammer.pointers.moved[p]
            if moved then
               local wx, wy = camera:worldCoords(moved.x, moved.y)
               self.child.data.cells[i][j].x = wx - self.child.pos.x + node.dx
               self.child.data.cells[i][j].y = wy - self.child.pos.y
               self.child.dirty=true
            end

         end


      end
   end





   ---------------------------
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

   ---------------------------

end



return mode
