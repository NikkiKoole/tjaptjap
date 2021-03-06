local utils = require "utils"

local shapes = require "shapes"
local mode = {}


function isTriangleHit(triangle, point)
   local t = triangle
   local t1 = {x=t[1], y=t[2]}
   local t2 = {x=t[3], y=t[4]}
   local t3 = {x=t[5], y=t[6]}
   local hit = pointInTriangle({x=point.x,y=point.y}, t1, t2, t3)
   return hit
end

function getFirstCollidingIndex(triangles, wx, wy)
   for j=1, #triangles do
      if isTriangleHit(triangles[j], {x=wx,y=wy}) then
         return j
      end
   end
   return 0
end

function getWithID(list, id)
   if (list) then
      for i=#list,1 ,-1 do
         if list[i].id == id then
            return  i
         end
      end
   end
   return -1
end

function mode:enter(from, data)
   self.child = data
   self.setPivot = false
   self.color_panel_opened = false
   self.selected_triangle = nil
   self.children_panel_opened = false
end

function mode:addVertex(x, y)
   local si, ni  = self:getClosestNodes(x, y)
   table.insert(self.child.data.points, ni, {x=x, y=y})
   self.child.dirty=true
end

function mode:addControlPoint(x,y)
   local si,ni = self:getClosestNodes(x, y)
   table.insert(self.child.data.points, ni, {cx=x, cy=y})
   self.child.dirty = true
end

function mode:removeVertexIfOverlappingWithNextOrPrevious(it)
   local points = self.child.data.points
   local next_i, prev_i = it.i + 1, it.i - 1

   if next_i > #points then next_i = 1 end
   if prev_i < 1 then prev_i = #points end

   local t, n, p = points[it.i], points[next_i], points[prev_i]
   local dn = utils.distance(t.x or t.cx, t.y or t.cy , n.x or n.cx, n.y or n.cy)
   local dp = utils.distance(t.x or t.cx, t.y or t.cy,  p.x or p.cx, p.y or p.cy)

   if (dp < 32 or dn < 32) then
      if #points > 3 then
         table.remove(self.child.data.points, it.i)
         local shape = shapes.makeShape(self.child)
         self.child.triangles = poly.triangulate(self.child.type, shape)
         mode:makeHandles()
      end
  end
end

function mode:removeLastTouched()
   if (self.lastTouchedIndex) then
      table.remove(self.child.data.points, self.lastTouchedIndex)
      assert(self.child)
      self.child.dirty = true
   end
end

function mode:getClosestNodes(x, y)
   local points = self.child.data.points
   local best_distance = math.huge
   local si = -1
   local ni = -1

   for i=1, #points do
      local self_index = i
      local next_index = i + 1

      if (i == #points) then
         next_index = 1
      end

      local this = points[self_index]
      local next = points[next_index]
      local d = utils.distancePointSegment(x, y,
                                           this.x or this.cx ,
                                           this.y or this.cy,
                                           next.x or next.cx,
                                           next.y or next.cy)

      if (d < best_distance) then
         best_distance = d
         si = self_index
         ni = next_index
      end
   end
   return si,ni
end
----- duplication

function dragger_color(ui, optional_color)
   local p = getWithID(Hammer.pointers.moved, ui.pointerID)
   local moved = Hammer.pointers.moved[p]
   if moved then
      if optional_color then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y, color=optional_color})
      else
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
      end
   end
end

function mode:releaser(ui, result)
   local p = getWithID(Hammer.pointers.released, ui.pointerID)
   local released = Hammer.pointers.released[p]
   local wx,wy = camera:worldCoords(released.x, released.y)
   wx,wy = self.child.inverse(wx,wy)

   result.pos.x = wx
   result.pos.y = wy
   result.world_pos={x=0,y=0,z=0}
   result.dirty = true

   if not self.child.children then self.child.children = {} end
   table.insert(self.child.children, result)
end

---------

local alpha1_value = {min=0, max=255, value=255}
local alpha2_value = {min=0, max=255, value=255}
local alpha3_value = {min=0, max=255, value=255}

function mode:selected_triangle_ui()
   Hammer:reset(10,200)

   if not self.child.data.vertex_colors then
      self.child.data.vertex_colors = {}
      local ti = 1
      while #self.child.triangles > #self.child.data.vertex_colors do
         local color = { {255,255,255,255} , {255,255,255,255}, {255,255,255,255} }
         if self.child.data.triangle_colors then
            local c = self.child.data.triangle_colors[ti]
            color[1] = {c[1], c[2], c[3], c[4]}
            color[2] = {c[1], c[2], c[3], c[4]}
            color[3] = {c[1], c[2], c[3], c[4]}
         end

         table.insert(self.child.data.vertex_colors, color)
         ti = ti + 1
      end
   end

   local colorbutton_used = false

   local set_color1 = Hammer:labelbutton("color 1", 80,40)
   local picked_color1 = Hammer:rectangle("picked_color1", 40,40, {color= self.child.data.vertex_colors[self.selected_triangle_index][1] or {255,255,255}})
   local value_a1 = alpha1_value.value
   local alpha1 = Hammer:slider("alpha1", 150,40, alpha1_value)

   if alpha1_value.value ~= value_a1 then
      self.child.data.vertex_colors[self.selected_triangle_index][1][4] = value_a1
   end

   Hammer:ret()
   local colors = {{255,0,0},{0,255,0},{0,0,255}, {0,255,255}, {255,0,255},{255,255,0}}
   for i=1, #colors do
      local colorbutton = Hammer:rectangle("color1"..tostring(i), 40, 40, {color=colors[i]})
      if colorbutton.released then
         colorbutton_used = true
         self.child.data.vertex_colors[self.selected_triangle_index][1] = colors[i]
      end
   end
   Hammer:ret()

   local set_color2 = Hammer:labelbutton("color 2", 80,40)
   local picked_color2 = Hammer:rectangle("picked_color2", 40,40, {color= self.child.data.vertex_colors[self.selected_triangle_index][2] or {255,255,255}})
   local value_a2 = alpha2_value.value
   local alpha2 = Hammer:slider("alpha2", 150,40, alpha2_value)

   if alpha2_value.value ~= value_a2 then
      self.child.data.vertex_colors[self.selected_triangle_index][2][4] = value_a2
   end

   Hammer:ret()
   for i=1, #colors do
      local colorbutton = Hammer:rectangle("color2"..tostring(i), 40, 40, {color=colors[i]})
      if colorbutton.released then
         colorbutton_used = true
         self.child.data.vertex_colors[self.selected_triangle_index][2] = colors[i]
      end
   end
   Hammer:ret()

   local set_color3 = Hammer:labelbutton("color 3", 80,40)
   local picked_color3 = Hammer:rectangle("picked_color3", 40,40, {color= self.child.data.vertex_colors[self.selected_triangle_index][3] or {255,255,255}})
   local value_a3 = alpha3_value.value
   local alpha3 = Hammer:slider("alpha3", 150,40, alpha3_value)

   if alpha3_value.value ~= value_a3 then
      self.child.data.vertex_colors[self.selected_triangle_index][3][4] = value_a3
   end

   if alpha1.released or  alpha2.released or alpha3.released then
      colorbutton_used = true
   end


   Hammer:ret()
   for i=1, #colors do
      local colorbutton = Hammer:rectangle("color3"..tostring(i), 40, 40, {color=colors[i]})
      if colorbutton.released then
         colorbutton_used = true
         self.child.data.vertex_colors[self.selected_triangle_index][3] = colors[i]
      end
   end
   Hammer:ret()


   local pressedHit = false
   if #Hammer.pointers.pressed == 1 then
      if Hammer:isDirty() then pressedHit = true end
      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)
      if isTriangleHit(self.selected_triangle, {x=wx,y=wy}) then
         pressedHit = true
      end
   end

   if #Hammer.pointers.released == 1  and not pressedHit  and not colorbutton_used then
      local wx, wy = camera:worldCoords(Hammer.pointers.released[1].x, Hammer.pointers.released[1].y)
      if not isTriangleHit(self.selected_triangle, {x=wx,y=wy}) then
         self.selected_triangle = nil
      end
   end

   if colorbutton_used then
   end
end

function getBBoxForTriangles(triangles)
   local minX = nil
   local minY = nil
   local maxX = nil
   local maxY = nil

   for ti=1, #triangles do
      local tri = triangles[ti]
      for i=1, 6, 2 do
         if minX == nil or minX > tri[i] then
            minX = tri[i]
         end
         if maxX == nil or maxX < tri[i] then
            maxX = tri[i]
         end
         --
         if minY == nil or minY > tri[i+1] then
            minY = tri[i+1]
         end
         if maxY == nil or maxY < tri[i+1] then
            maxY = tri[i+1]
         end
      end
   end
   return {minX=minX, minY=minY, maxX=maxX, maxY=maxY}
end


function mode:update()
   local child = self.child

   -- if self.selected_triangle ~= nil then
   --    mode:selected_triangle_ui()
   --    return
   -- end



   local shape = shapes.makeShape(child)
   local bbminx, bbminy, bbmaxx, bbmaxy= shapes.getShapeBBox(shape)

   Hammer:reset(10,200)
   Hammer:pos(0,0)

   local p = child.pivot
   local rx2, ry2 = camera:cameraCoords( child.world_trans(p and p.x or 0, p and p.y or 0) )
   local pivot = Hammer:rectangle( "pivot", 30, 30,{x=rx2-15, y=ry2-15, color=color})

   makePivotBehaviour(pivot, child)

   local rx1, ry1 = camera:cameraCoords( child.world_trans(  (p and p.x or 0) + (bbmaxx-bbminx)/2 ,  (p and p.y or 0)) )
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

   for i=1, #child.data.points do
      local point = child.data.points[i]
      local cx2, cy2 = camera:cameraCoords(child.world_trans((point.x or point.cx), (point.y or point.cy)))

      local color
      if point.x and point.y then
         color={0,100,100}
      else
         color={200,100,100}
      end

      local button = Hammer:rectangle( "poly-handle"..i, 30, 30, {x=cx2-15, y=cy2-15, color=color})

      if button.pressed then
         self.lastTouchedIndex = i
      end

      if not rotator.dragging and not pivot.dragging then
         if button.dragging then
            self.lastTouchedIndex = i

            local p = getWithID(Hammer.pointers.moved, button.pointerID)
            local moved = Hammer.pointers.moved[p]
            if moved then

               local wx,wy = camera:worldCoords(moved.x-button.dx, moved.y-button.dy)
               wx,wy = self.child.inverse(wx,wy)

               if point.x and point.y then
                  self.child.data.points[i].x = wx
                  self.child.data.points[i].y = wy
               elseif point.cx and point.cy then
                  self.child.data.points[i].cx = wx
                  self.child.data.points[i].cy = wy
               end
               self.child.dirty = true
            end
         end
      end
   end

   Hammer:pos(0,30)
   Hammer:label( "full_path", getFullGraphName(child, ""), SCREEN_WIDTH,20)
   Hammer:pos(20,100)

   local text_input = Hammer:textinput("name-input", self.child.id or "unnamed", 150, 40)
   if text_input.text ~= self.child.id then
      self.child.id = text_input.text
   end
   Hammer:ret()

   if self.child.parent.id ~= "world" then
      if Hammer:labelbutton("parent ("..self.child.parent.id..")", 120, 40).released then
         local it = self.child.parent
         if it.type == "polygon" then
            Signal.emit("switch-state", "edit-polygon", it)
         elseif it.type == "smartline" then
            Signal.emit("switch-state", "edit-smartline", it)
         end
      end
         Hammer:ret()
   end

   --------- panel that shows direct children and has a generic parent button
   if self.child.children and #self.child.children > 0 then
      if Hammer:labelbutton("children", 120, 40).released then
         self.children_panel_opened = not self.children_panel_opened
      end
   end
   Hammer:ret();

   if self.children_panel_opened then
      if self.child.children then
         for i=1, #self.child.children do


            local it = self.child.children[i]
            if Hammer:labelbutton(it.id, 120, 40).released then
               if it.type == "polygon" then
                  Signal.emit("switch-state", "edit-polygon", it)
                  break
               elseif it.type == "smartline" then
                  Signal.emit("switch-state", "edit-smartline", it)
                  break
               end
            end
            local below = it.belowParent
            if Hammer:labelbutton(below and "<" or ">" , 20, 20).released then
               self.child.children[i].belowParent = not self.child.children[i].belowParent
            end

            Hammer:ret()
         end
      end
   end
   ---------
   local bbox = getBBoxForTriangles(self.child.triangles)
   Hammer:label("bbox", "W, H: "..math.floor(bbox.maxX - bbox.minX)..", "..math.floor(bbox.maxY - bbox.minY), 140, 20)
   Hammer:ret()

--   Hammer:label("bboxw", math.floor(bbox.maxY - bbox.minY).."px H", 100, 20)

   Hammer:label("triscount", "#tris:"..#(self.child.triangles), 100, 20)

   local copy_to_clip = Hammer:labelbutton("copy", 120,20)
   if copy_to_clip.released then
      Signal.emit("copy-to-clipboard", self.child)

   end


   Hammer:ret()
   local add_shape = Hammer:labelbutton("child line", 120,40)
   if add_shape.released then
      self.touches = {}
      if not self.child.children then self.child.children = {} end
      Signal.emit("switch-state", "draw-line", {pointerID=id, parent=self.child})
   end






   Hammer:ret()
   local add_polygon = Hammer:labelbutton( "child poly", 120,40)
   if add_polygon.dragging then
      dragger(add_polygon)
   end
   if add_polygon.released then
      local result = {
         type="polygon",
         id="polygon_"..tostring(math.floor(math.random()*20)),
         pos={x=0, y=0, z=0},
         data={ steps=3,  points={{x=200,y=0}, {x=200, y=200}, {x=0, y=250}} }
      }
      self:releaser(add_polygon, result)
   end
   Hammer:ret()
   Hammer:ret()

   --  -- palette
   -- local set_color = Hammer:labelbutton("color", 80,40)
   -- local picked_color = Hammer:rectangle("picked_color", 40,40, {color=self.child.color or {255,255,255}})

   -- if set_color.released or picked_color.released then
   --    self.color_panel_opened =  not self.color_panel_opened
   -- end
   -- Hammer.x = Hammer.x + 20
   -- if self.color_panel_opened then
   --    local colors = {
   --       {241, 255, 240},
   --       {116, 100, 75},
   --       {241, 185, 146},
   --       {190, 122, 95},
   --       {164, 56, 56},
   --       {75,158,249},
   --       {69,218,214},
   --       {89,241,147},
   --       {106, 218,69},
   --       {242,249,12}

   --    }

   --     --local colors = {{255,0,0},{0,255,0},{0,0,255}, {0,255,255}, {255,0,255},{255,255,0}}
   --     for i=1, #colors do
   --        local colorbutton = Hammer:rectangle("color"..tostring(i), 40, 40, {color=colors[i]})
   --        if colorbutton.released then
   --           self.child.color = colors[i]
   --           self.child.color_setting = "triple"
   --        end
   --     end
   -- end
   -- Hammer:ret()
   -- Hammer:ret()




   local add_vertex = Hammer:labelbutton("vertex =>", 120,40)
   if add_vertex.dragging then
      local p = getWithID(Hammer.pointers.moved, add_vertex.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
         local wx,wy = camera:worldCoords(moved.x, moved.y)
         wx,wy = child.inverse(wx,wy)

         local si,ni =mode:getClosestNodes(wx,wy)
         si = self.child.data.points[si]
         ni = self.child.data.points[ni]

         local x2, y2 = child.world_trans(si.x or si.cx, si.y or si.cy)
         x2,y2 = camera:cameraCoords(x2,y2)
         Hammer:circle("si", 10, {x=x2, y=y2})
         x2, y2 = child.world_trans(ni.x or ni.cx, ni.y or ni.cy)
         x2,y2 = camera:cameraCoords(x2,y2)
         Hammer:circle("ni", 10, {x=x2, y=y2})
      end
   end
   if add_vertex.enddrag then
      local p = getWithID(Hammer.pointers.released, add_vertex.pointerID)
      local released = Hammer.pointers.released[p]
      local wx,wy = camera:worldCoords(released.x, released.y)
      wx,wy = child.inverse(wx,wy)

      self:addVertex(wx, wy)
   end

   Hammer:ret()
   local add_cp = Hammer:labelbutton("bezier =>", 120,40)
   if add_cp.dragging then
      local p = getWithID(Hammer.pointers.moved, add_cp.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor2", 30, {x=moved.x, y=moved.y})
         local wx,wy = camera:worldCoords(moved.x, moved.y)
         wx,wy = child.inverse(wx,wy)

         local si,ni =mode:getClosestNodes(wx,wy)
         si = self.child.data.points[si]
         ni = self.child.data.points[ni]

         local x2, y2 = child.world_trans(si.x or si.cx, si.y or si.cy)
         x2,y2 = camera:cameraCoords(x2,y2)
         Hammer:circle("si", 10, {x=x2, y=y2})
         x2, y2 = child.world_trans(ni.x or ni.cx, ni.y or ni.cy)
         x2,y2 = camera:cameraCoords(x2,y2)
         Hammer:circle("ni", 10, {x=x2, y=y2})

      end
   end
   if add_cp.enddrag then
      local p = getWithID(Hammer.pointers.released, add_cp.pointerID)
      local released = Hammer.pointers.released[p]
      local wx,wy = camera:worldCoords(released.x, released.y)
      wx,wy = child.inverse(wx,wy)

      self:addControlPoint(wx, wy)
   end

   Hammer:ret()
   local delete = Hammer:labelbutton("delete", 120, 40)
   if delete.startpress then
      for i=#self.child.parent.children,1,-1 do
         if self.child.parent.children[i]==self.child then
            table.remove(self.child.parent.children, i)
            Signal.emit("switch-state", "stage")
         end
      end
   end

   Hammer:ret()
   Hammer:ret()

   if self.lastTouchedIndex then
      local del_node = Hammer:labelbutton("delete last", 120,40)
      if del_node.released then
         mode:removeLastTouched()
         self.lastTouchedIndex = false
      end
   end

   ------ drag colors onto triangles
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
      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)
      local isDirty = Hammer:isDirty()

      if not isDirty then
         local fci = getFirstCollidingIndex(self.child.triangles, wx, wy)
         if fci > 0 then
            isDirty = true
            self.selected_triangle = self.child.triangles[fci]
            self.selected_triangle_index = fci
            alpha1_value.value = self.child.data.vertex_colors and self.child.data.vertex_colors[fci][1][4] or 255
            alpha2_value.value = self.child.data.vertex_colors and self.child.data.vertex_colors[fci][2][4] or 255
            alpha3_value.value = self.child.data.vertex_colors and self.child.data.vertex_colors[fci][3][4] or 255
         end
      end

      --if not isDirty then
         if self.child.children then
            for i=1,#self.child.children do
               local hit = pointInPoly({x=wx,y=wy}, self.child.children[i].triangles)
               if hit then
                  Signal.emit("switch-state", "drag-item", {child=self.child.children[i], pointerID=Hammer.pointers.pressed[1].id})
                  isDirty=true
               end
            end
         end
      --end

      if not isDirty then
         Signal.emit("switch-state", "stage")
      end
   end
end

return mode
