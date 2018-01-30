local mode = {}

local thickness_value = {min=1, max=100, value=50}


function angleToRelative(a)
   return (math.pi * 2) - (a + math.pi/2)
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



function calculateAllPropsFromCoords(coords)
   local result = {relative_rotations={}, world_rotations={}, lengths={}}
   local world_rotation = 0
   local counter = 1
   for i=1, #coords-2, 2 do
      local thisX = coords[i+0]
      local thisY = coords[i+1]
      local nextX = coords[i+2]
      local nextY =  coords[i+3]
      local a = utils.angle(  nextX, nextY,thisX, thisY)
      local d = utils.distance( thisX, thisY, nextX, nextY)
      local wa = angleToWorld(a)

      table.insert(result.relative_rotations, angleToRelative(a)  )

      if counter > 1 then
         local diff = (result.relative_rotations[counter]-  result.relative_rotations[counter-1] )
         table.insert(result.world_rotations, diff  )
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
   self.bestIndex =  -1
   self.lastActiveIndex = -1

   for i=1, #self.lineOptions do
      if self.lineOptions[i]==data.data.type then
         self.lineOptionIndex = i
      end
   end
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
   Hammer:reset(10,200)

   if Hammer:labelbutton(self.lineOptions[self.lineOptionIndex], 100, 40).released then
      self.lineOptionIndex = self.lineOptionIndex + 1
      if self.lineOptionIndex > #self.lineOptions then
         self.lineOptionIndex = 1
      end
      self.child.data.type = self.lineOptions[self.lineOptionIndex]
   end

   local add_vertex = Hammer:labelbutton("add vertex", 100,60)

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

   if self.lastActiveIndex > -1 then
      Hammer:label("thickness node", "thickness: ", 150, 30)
      Hammer:ret()

      local value = thickness_value.value
      local thickness_slider = Hammer:slider("thickness", 200,40, thickness_value)
      if thickness_value.value ~= value then
         self.child.data.thicknesses[self.lastActiveIndex] = math.floor(thickness_value.value)
         self.child.dirty = true
      end

   end

   if self.lastActiveIndex > -1 then
   local del_node = Hammer:labelbutton("delete last", 140,40)
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

   Hammer:ret()
   local delete = Hammer:labelbutton("delete", 100, 40)
   if delete.startpress then
      for i=#world.children,1,-1 do
         if world.children[i]==self.child then
            table.remove(world.children, i)
            Signal.emit("switch-state", "stage")
         end
      end
   end

   local none  = Hammer:labelbutton("none", 60,30)
   if none.startpress then
      self.child.data.join = "none"
      self.child.dirty = true
   end
   local miter = Hammer:labelbutton("miter", 60,30)
   if miter.startpress then
      self.child.data.join = "miter"
      self.child.dirty = true
   end
   local bevel = Hammer:labelbutton("bevel", 60,30)
   if bevel.startpress then
      self.child.data.join = "bevel"
      self.child.dirty = true
   end





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
               if i > 1 then
                  local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                  local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)

                  child.data.relative_rotations[-1 + (i+1)/2] =  angleToRelative(ap)

                  local p2 = calculateAllPropsFromCoords(child.data.coords)
                  child.data.lengths = p2.lengths

                  --child.data.lengths[-1 + (i+1)/2] = dp


                  local new_coords = utils.calculateCoordsFromRotationsAndLengths(true, child.data)
                  child.data.coords = new_coords

                  local props = calculateAllPropsFromCoords(child.data.coords)
                  child.data.relative_rotations = props.relative_rotations
                  child.data.world_rotations = props.world_rotations

               end
            elseif recipe == "world" then
               if i > 1 then
                  local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                  local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)
                  local startAngle = mode:getNestedRotation(((i+1)/2)-2)

                  --child.data.lengths[-1 + (i+1)/2] = dp
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
         Signal.emit("switch-state", "stage")
      end
   end
end



return mode
