local mode = {}
local utils = require "utils"

function mode:enter(from,data)
   self.child = data
end

function mode:update(dt)
   local color = {200,100,100}

   Hammer:reset(0,0)

   local data = self.child.data
   for i=1, data.width+1 do
      for j=1, data.height+1 do
         local rx,ry = camera:cameraCoords(data.cells[i][j].x +self.child.pos.x, data.cells[i][j].y+self.child.pos.y)
         local node = Hammer:rectangle( "n"..i..","..j, 30, 30,{x=rx-15, y=ry-15, color=color})
         if node.dragging then
            local p = getWithID(Hammer.pointers.moved, node.pointerID)
            local moved = Hammer.pointers.moved[p]
            if moved then
               local wx, wy = camera:worldCoords(moved.x, moved.y)
               wx = wx - node.dx/camera.scale - self.child.pos.x
               wy = wy - node.dy/camera.scale - self.child.pos.y
               self.child.data.cells[i][j].x = wx
               self.child.data.cells[i][j].y = wy
               self.child.dirty=true
            end
         end
      end
   end


      Hammer:ret()
   Hammer:pos(10,love.graphics.getHeight()- 50)

   local colors = {
         {241, 255, 240},
         {116, 100, 75},
         {241, 185, 146},
         {190, 122, 95},
         {164, 56, 56},
         {75,158,249},
         {69,218,214},
         {89,241,147},
         {106, 218,69},
         {242,249,12},
         {174, 22, 73},
         {210, 51, 89},
         {231, 91, 134},
         {0, 38, 37},
         {244, 62, 56}


   }

   --local colors = {{255,0,0},{255,0,255},{0,255,0}, {0,0,255},{0,255,255},{255,255,0},{0,0,0},{125,125,125},{255,255,255}}

   for i=1, #colors do
      local colorbutton = Hammer:rectangle("color_dragger_"..tostring(i), 40, 40, {color=colors[i]})

      if colorbutton.dragging then
         dragger_color(colorbutton, colors[i])
      end
      if colorbutton.released then
         local p = getWithID(Hammer.pointers.released, colorbutton.pointerID)
         local released = Hammer.pointers.released[p]
         local wx,wy = camera:worldCoords(released.x, released.y)
         local fci = getFirstCollidingIndex(self.child.triangles, wx, wy)

         if fci > 0 then
            if not self.child.data.triangle_colors then
               self.child.data.triangle_colors = {}
               while #self.child.triangles > #self.child.data.triangle_colors do
                  if (self.child.color) then
                     table.insert(self.child.data.triangle_colors, {self.child.color[1], self.child.color[2], self.child.color[3], self.child.color[4]}  )
                  else
                     table.insert(self.child.data.triangle_colors, {colors[i][1], colors[i][2], colors[i][3], colors[i][4]})
                  end
               end
            else
            end
            self.child.data.triangle_colors[fci] = colors[i]
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
