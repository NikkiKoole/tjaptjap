local mode = {}
local thickness_value = {min=1, max=100, value=50}

function angleToRelative(a)
   local result = ((math.pi * 2) - (a + math.pi/2))
   if result > 0 then result = result % (math.pi*2) end
   if result < 0 then result = result % (-math.pi*2) end

   return result
end

function angleToWorld(a)
   return (a*-1) - (math.pi/2)
end

function getClosestNodeIndex(x, y, coords)
   local best_distance = math.huge
   local index = -1
   local insertIndex = -1
   for i=1, #coords, 2 do
      local d = utils.distance(x,y,coords[i+0],coords[i+1])
      if d < best_distance then
         index = (i+1)/2
         best_distance = d
      end
   end
   -- at this moment you have the index of the closestNode
   -- now we look and see if my current pos is closer to the next node after the closest then the closest itself is
   local i2 = index*2-1
   if (i2+1 < #coords) then
      local d1 = utils.distance(x,y,coords[i2+2],coords[i2 + 3])
      local d2 = utils.distance(coords[i2+0],coords[i2 + 1],coords[i2+2],coords[i2 + 3])
      if d1 > d2 then index = index-1 end
   end
   return index
end

function calculateAllPropsFromCoordsReverse(coords)
   local result = {relative_rotations={}, world_rotations={}, lengths={}}
   local world_rotation = 0
   local counter = 1

   --print(inspect(coords))
   for i=#coords,1 ,-2 do
      print(coords[i-1],  coords[i])
   end

end

function calculateAllPropsFromCoords(coords)
   local result = {relative_rotations={}, world_rotations={}, lengths={}}
   local world_rotation = 0
   local counter = 1
   for i=1, #coords-2, 2 do

      local a = utils.angle(  coords[i+2],  coords[i+3], coords[i+0],  coords[i+1])
      local d = utils.distance( coords[i+0],  coords[i+1], coords[i+2],  coords[i+3])
      local wa = angleToWorld(a)

      table.insert(result.relative_rotations, angleToRelative(a)  )
      if counter > 1 then
         local diff = (result.relative_rotations[counter] - result.relative_rotations[counter-1] )
         table.insert(result.world_rotations, diff % (math.pi*2)  )
      else
         table.insert(result.world_rotations, result.relative_rotations[1])
      end
      world_rotation = wa + world_rotation
      table.insert(result.lengths, d)
      counter = counter + 1
   end
   return result
end

function round(value)
   if math.floor(value + 0.5) > math.floor(value) then
      return math.floor(value + 0.5)
   else
      return math.floor(value)
   end
end

function mode:enter(from, data)
   self.child = data
   self.rot = 0
   self.lineOptions = {"coords", "relative", "world"}
   self.lineOptionIndex = 1
   self.lineStyleOptions = {"miter", "bevel","none"}
   self.lineStyleOptionIndex = 1
   self.bestIndex =  -1
   self.lastActiveIndex = -1
   self.inverseWorldRotations = false
   for i=1, #self.lineOptions do
      if self.lineOptions[i]==data.data.type then
         self.lineOptionIndex = i
      end
   end
   self.children_panel_opened = false
end

function mode:getNestedRotation(index)
   local result = 0
   for i=index,1,-1 do
      if self.child.data.world_rotations[i] then
         result = result + self.child.data.world_rotations[i]
      end
   end
   return result
end

function mode:update(dt)
   local child = self.child
   Hammer:reset(0,30)
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
            local below = self.child.children[i].belowParent
            if Hammer:labelbutton(below and "<" or ">" , 20, 20).released then
               self.child.children[i].belowParent = not self.child.children[i].belowParent
            end

            Hammer:ret()
         end
      end
   end
   ---------






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
   local add_polygon = Hammer:labelbutton("child poly", 120,40)

   if add_polygon.dragging then
      dragger(add_polygon)
   end
   if add_polygon.released then
      local result = {
         type="polygon",
         id="polygon_"..tostring(math.floor(math.random()*20)),
         pos={x=0, y=0, z=0},
         data={ steps=3,  points={{x=0,y=-100}, {cx=100, cy=-100},{cx=200, cy=-100},{cx=300, cy=-100}, {x=200,y=0}, {x=200, y=200}, {x=0, y=250}} }
      }
      self:releaser(add_polygon, result)
   end
   Hammer:ret()

   -- -- palette
   -- local set_color = Hammer:labelbutton("color", 80,40)
   -- local picked_color = Hammer:rectangle("picked_color", 40,40, {color=self.child.color or {255,255,255}})

   -- if set_color.released or picked_color.released then
   --    self.color_panel_opened =  not self.color_panel_opened
   -- end
   -- Hammer.x = Hammer.x + 20
   -- if self.color_panel_opened then
   --     local colors = {{255,0,0},{255,0,255},{0,255,0}, {0,0,255},{0,255,255},{255,255,0}}
   --     for i=1, #colors do
   --        local colorbutton = Hammer:rectangle("color"..tostring(i), 40, 40, {color=colors[i]})
   --        if colorbutton.released then
   --           self.child.color = colors[i]
   --           self.child.color_setting = "triple"
   --        end
   --     end
   -- end

   Hammer:ret()

   local add_vertex = Hammer:labelbutton("add vertex =>", 120,40)
   if add_vertex.dragging then
      local p = getWithID(Hammer.pointers.moved, add_vertex.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
         local wx,wy = camera:worldCoords(moved.x, moved.y)
         wx,wy = child.inverse(wx,wy)
         local closestNodeIndex = getClosestNodeIndex(wx,wy, child.data.coords)
         self.bestIndex =  closestNodeIndex
      end
   end
   if add_vertex.enddrag then
      local p = getWithID(Hammer.pointers.released, add_vertex.pointerID)
      local released = Hammer.pointers.released[p]
      if released then
         local wx,wy = camera:worldCoords(released.x, released.y)
         wx,wy = child.inverse(wx,wy)
         local closestNodeIndex = getClosestNodeIndex(wx,wy, child.data.coords)
         local i = (closestNodeIndex*2) + 1
         table.insert(self.child.data.coords, i, wy)
         table.insert(self.child.data.coords, i, wx)
         table.insert(self.child.data.thicknesses, closestNodeIndex+1, 20)

         local props = calculateAllPropsFromCoords(child.data.coords)
         child.data.relative_rotations = props.relative_rotations
         child.data.world_rotations = props.world_rotations
         child.data.lengths = props.lengths
         self.bestIndex =  -1
         self.child.dirty = true
      end
   end

   Hammer:ret()
   if Hammer:labelbutton("("..self.lineOptionIndex..") "..self.lineOptions[self.lineOptionIndex], 120, 40).released then
      self.lineOptionIndex = self.lineOptionIndex + 1
      if self.lineOptionIndex > #self.lineOptions then
         self.lineOptionIndex = 1
      end
      self.child.data.type = self.lineOptions[self.lineOptionIndex]
   end
   if self.lineOptions[self.lineOptionIndex] == "world" then
      if Hammer:labelbutton(self.inverseWorldRotations == false and "NRM" or "INV" , 40,40).released then
         self.inverseWorldRotations = not self.inverseWorldRotations
      end
   end
   if self.lineOptions[self.lineOptionIndex] == "relative" then
      if Hammer:labelbutton(self.inverseWorldRotations == false and "NRM" or "INV" , 40,40).released then
         self.inverseWorldRotations = not self.inverseWorldRotations
      end
   end



   Hammer:ret()
   local lineStyle = Hammer:labelbutton("("..self.lineStyleOptionIndex..") "..self.lineStyleOptions[self.lineStyleOptionIndex], 120, 40)
   if lineStyle.released then
      self.lineStyleOptionIndex = self.lineStyleOptionIndex + 1
      if self.lineStyleOptionIndex > #self.lineStyleOptions then
         self.lineStyleOptionIndex = 1
      end
      self.child.data.join = self.lineStyleOptions[self.lineStyleOptionIndex]
      self.child.dirty = true
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




   if self.lastActiveIndex > -1 then
      Hammer:ret()
      local value = thickness_value.value
      local thickness_slider = Hammer:slider("thickness", 200,40, thickness_value)
      if thickness_value.value ~= value then
         self.child.data.thicknesses[self.lastActiveIndex] = math.floor(thickness_value.value)
         self.child.dirty = true
      end
   end

   if self.lastActiveIndex > -1 then
      Hammer:ret()

      local del_node = Hammer:labelbutton("delete last", 120,40)
      if del_node.released then
         local index = self.lastActiveIndex -1
         table.remove(self.child.data.thicknesses, index+1)
         table.remove(child.data.coords, index*2+1)
         table.remove(child.data.coords, index*2+1)
         local props = calculateAllPropsFromCoords(child.data.coords)
         child.data.relative_rotations = props.relative_rotations
         child.data.world_rotations = props.world_rotations
         child.data.lengths = props.lengths

         self.child.dirty=true
         self.lastActiveIndex = -1
         if #child.data.coords <4 then
            for i=#world.children,1,-1 do
               if world.children[i]==self.child then
                  table.remove(world.children, i)
                  Signal.emit("switch-state", "stage")
               end
            end
         end
      end
   end


   ------ drag colors onto triangles
   Hammer:ret()

   Hammer:pos(10,love.graphics.getHeight()- 50)
   -- TODO make this palette global
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


   for i=1, #colors do
      local colorbutton = Hammer:rectangle("color_dragger_"..tostring(i), 40, 40, {color=colors[i]})

      if colorbutton.dragging then
         dragger_color(colorbutton, colors[i])
      end
      if colorbutton.released then
         local p = getWithID(Hammer.pointers.released, colorbutton.pointerID)
         local released = Hammer.pointers.released[p]
         local wx,wy = camera:worldCoords(released.x, released.y)

         for j=1, #self.child.triangles do
            local t = self.child.triangles[j]
            local t1 = {x=t[1], y=t[2]}
            local t2 = {x=t[3], y=t[4]}
            local t3 = {x=t[5], y=t[6]}
            local hit = pointInTriangle({x=wx,y=wy}, t1, t2, t3)
            if hit then
               if not self.child.data.triangle_colors then
                  self.child.data.triangle_colors = {}
                  while #self.child.triangles > #self.child.data.triangle_colors do
                     if self.child.color then
                        table.insert(self.child.data.triangle_colors, {self.child.color[1], self.child.color[2], self.child.color[3], self.child.color[4]})
                     else
                        table.insert(self.child.data.triangle_colors, {colors[i][1], colors[i][2], colors[i][3], colors[i][4]} )
                     end

                  end
               else
               end
               self.child.data.triangle_colors[j] = {colors[i][1], colors[i][2], colors[i][3], colors[i][4]} -- colors[i]
            end

         end
      end
   end

   -----------------------------


   Hammer:pos(0,0)
   local recipe = self.lineOptions[self.lineOptionIndex]

   for i=1, #child.data.coords, 2 do
      local x,y = child.data.coords[i], child.data.coords[i+1]
      local cx2, cy2 = camera:cameraCoords(child.world_trans(x,y))
      local color = {200,200,200}
      local button = Hammer:rectangle( "smartline-handle"..i, 30, 30,
                                       {x=cx2-15, y=cy2-15, color=color})
      if button.startpress then
         self.lastActiveIndex = (i+1)/2
         thickness_value.value = child.data.thicknesses[self.lastActiveIndex] or 0
      end
      if (self.bestIndex == (i+1)/2 ) then
         Hammer:circle("bestindex", 30, {x=cx2, y=cy2})
      end

      if button.dragging then
         local p = getWithID(Hammer.pointers.moved, button.pointerID)
         local moved = Hammer.pointers.moved[p]
         if moved then
            local wx,wy = camera:worldCoords(moved.x-button.dx, moved.y-button.dy)
            wx,wy = child.inverse(wx,wy)

            if recipe == 'coords' then
               child.data.coords[i  ] = wx
               child.data.coords[i+1] = wy
               local props = calculateAllPropsFromCoords(child.data.coords)
               child.data.relative_rotations = props.relative_rotations
               child.data.world_rotations = props.world_rotations
               child.data.lengths = props.lengths

            elseif recipe == 'relative' then
               if self.inverseWorldRotations == true then
                  print("This does not work TODO")
                  calculateAllPropsFromCoordsReverse(child.data.coords)
               else
                  if i > 1 then
                     local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                     local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)
                     child.data.relative_rotations[-1 + (i+1)/2] =  angleToRelative(ap)
                     local p2 = calculateAllPropsFromCoords(child.data.coords)
                     child.data.lengths = p2.lengths
                     local new_coords = utils.calculateCoordsFromRotationsAndLengths(true, child.data)
                     child.data.coords = new_coords
                     local props = calculateAllPropsFromCoords(child.data.coords)
                     child.data.relative_rotations = props.relative_rotations
                     child.data.world_rotations = props.world_rotations
                  end
               end
            elseif recipe == "world" then
               if self.inverseWorldRotations == true then
                  print("This does not work TODO")
                  calculateAllPropsFromCoordsReverse(child.data.coords)
               else
                  if i > 1 then
                     local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                     local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)
                     --print(((i+1)/2)-2)
                     local startAngle = mode:getNestedRotation(((i+1)/2)-2)
                     child.data.world_rotations[-1+(i+1)/2] = angleToWorld(ap) - startAngle
                     local p2 = calculateAllPropsFromCoords(child.data.coords)
                     child.data.lengths = p2.lengths
                     local new_coords = utils.calculateCoordsFromRotationsAndLengths(false, child.data)
                     child.data.coords = new_coords
                     local props = calculateAllPropsFromCoords(child.data.coords)
                     child.data.relative_rotations = props.relative_rotations
                     child.data.world_rotations = props.world_rotations
                  end
               end

            end

            child.dirty = true
         end
      end
   end





   if #Hammer.pointers.pressed == 1 then
      local isDirty = Hammer:isDirty()
      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)
      if pointInPoly({x=wx,y=wy}, self.child.triangles) then
         isDirty = true
      end

      if not isDirty then
         if self.child.children then
            for i=1,#self.child.children do
               local hit = pointInPoly({x=wx,y=wy}, self.child.children[i].triangles)
               if hit then
                  --print("dragging a child!")
                  Signal.emit("switch-state", "drag-item", {child=self.child.children[i], pointerID=Hammer.pointers.pressed[1].id})
                  isDirty=true
               end
            end
         end
      end

      if not isDirty then
         Signal.emit("switch-state", "stage")
      end
   end
end

----
-- @duplication

   function dragger(ui)
      local p = getWithID(Hammer.pointers.moved, ui.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
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
---------------




return mode
