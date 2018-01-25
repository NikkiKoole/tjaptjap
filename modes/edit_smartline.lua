local mode = {}


function angleToRelative(a)
   return (math.pi * 2) - (a + math.pi/2)
end

function angleToWorld(a)
   return (a*-1) - (math.pi/2)
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
      --local a2 = utils.angle(  thisX, thisY,nextX, nextY)
      --print(a,a2)

      local d = utils.distance( thisX, thisY, nextX, nextY)

      local wa = angleToWorld(a)
      --print(i, wa, world_rotation )

      table.insert(result.relative_rotations, angleToRelative(a)  )
      --table.insert(result.relative_rotations, wa )


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

function calculateCoordsFromRotationsAndLengths(relative, data)
   local result = {}
   local rotation = 0
   local cx = data.coords[1]
   local cy = data.coords[2]

   table.insert(result, (cx))
   table.insert(result, (cy))

   if relative then
      for i=1,  #data.relative_rotations do
         cx, cy = utils.moveAtAngle(cx, cy, data.relative_rotations[i] , data.lengths[i])
         table.insert(result, (cx))
         table.insert(result, (cy))
      end
   else
      for i=1,  #data.world_rotations do
         rotation = data.world_rotations[i] + rotation
         cx, cy = utils.moveAtAngle(cx, cy, rotation , data.lengths[i])
         table.insert(result, (cx))
         table.insert(result, (cy))

      end
   end

   return result
end



function mode:enter(from, data)
   self.child = data
   self.rot = 0

   --  , rope

   -- TODO remove this
   local props = calculateAllPropsFromCoords(self.child.data.coords)
   self.child.data.relative_rotations = props.relative_rotations
   self.child.data.world_rotations    = props.world_rotations
   self.child.data.lengths            = props.lengths


   self.lineOptions = {"coords", "relative", "world"}
   self.lineOptionIndex = 1
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
   end


   Hammer:pos(0,0)
   local recipe = self.lineOptions[self.lineOptionIndex]


   for i=1, #child.data.coords, 2 do
      local x,y = child.data.coords[i], child.data.coords[i+1]
      local cx2, cy2 = camera:cameraCoords(child.world_trans(x,y))
      local color = {200,200,200}

      local button = Hammer:rectangle( "smartline-handle"..i, 30, 30,
                                       {x=cx2-15, y=cy2-15, color=color})

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
                  child.data.lengths[-1 + (i+1)/2] = dp

                  local new_coords = calculateCoordsFromRotationsAndLengths(true, child.data)
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


                  local new_coords = calculateCoordsFromRotationsAndLengths(false, child.data)
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


--DEBUGGING PART
   -- local props = calculateAllPropsFromCoords(child.data.coords)
   -- child.data.relative_rotations = props.relative_rotations
   -- child.data.world_rotations = props.world_rotations
   -- child.data.lengths = props.lengths

   -- print("relative rotations")
   -- print(inspect(child.data.relative_rotations))
   -- print("world rotations")
   -- print(inspect(child.data.world_rotations))

   -- local relative = calculateCoordsFromRotationsAndLengths(true, child.data)
   -- local world    = calculateCoordsFromRotationsAndLengths(false, child.data)
   -- print("the next three coords must be identical")
   -- print(inspect(child.data.coords))
   -- print(inspect(relative))
   -- print(inspect(world))



   if #Hammer.pointers.pressed == 1 then
      local isDirty = false
      isDirty = Hammer:isDirty()

      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)
      local hit = pointInPoly({x=wx,y=wy}, self.child.triangles)
      if hit then
         isDirty = true
         --print("point in poly dirty")

      end

      if not isDirty then
         Signal.emit("switch-state", "stage")
      end
   end



end






return mode
