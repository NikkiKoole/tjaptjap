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
   for i=1, #coords-2, 2 do
      local thisX = coords[i+0]
      local thisY = coords[i+1]
      local nextX = coords[i+2]
      local nextY =  coords[i+3]
      local a = utils.angle(  nextX, nextY,thisX, thisY)
      local d = utils.distance( thisX, thisY, nextX, nextY)

      table.insert(result.relative_rotations, angleToRelative(a)  )
      table.insert(result.world_rotations, angleToWorld(a) - mode:getNestedRotation((i+1)/2) )
      table.insert(result.lengths, d)

      world_rotation = world_rotation - angleToWorld(a)
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

   table.insert(result, round(cx))
   table.insert(result, round(cy))

   if relative then
      for i=1,  #data.relative_rotations do
         cx, cy = utils.moveAtAngle(cx, cy, data.relative_rotations[i] , data.lengths[i])
         table.insert(result, round(cx))
         table.insert(result, round(cy))
      end
   else
      for i=1,  #data.world_rotations do

         cx, cy = utils.moveAtAngle(cx, cy, data.world_rotations[i]  +  rotation , data.lengths[i])
         table.insert(result, round(cx))
         table.insert(result, round(cy))
         rotation = data.world_rotations[i] + rotation

      end
   end

   return result
end



function mode:enter(from, data)
   self.child = data
   self.rot = 0
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
   Hammer:reset(0,0)


   -- now i want to drag a node and move the rest with it

   local recipe = 'world' --'relative'


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
            elseif recipe == 'relative' then
               if i > 1 then
                  local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                  local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)

                  child.data.relative_rotations[-1 + (i+1)/2] =  angleToRelative(ap)
                  child.data.lengths[-1 + (i+1)/2] = dp

                  local new_coords = calculateCoordsFromRotationsAndLengths(true, child.data)
                  child.data.coords = new_coords
               end
            elseif recipe == "world" then
               if i > 1 then
                  local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                  local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)
                  --local startAngle = mode:getNestedRotation(i-1)
                  local startAngle = mode:getNestedRotation(((i+1)/2)- 2)


                  child.data.world_rotations[-1 + (i+1)/2] = angleToWorld(ap) - startAngle
                  child.data.lengths[-1 + (i+1)/2] = dp

                  local new_coords = calculateCoordsFromRotationsAndLengths(false, child.data)
                  child.data.coords = new_coords
               end


            end

            child.dirty = true
         end
      end
   end

   local props = calculateAllPropsFromCoords(child.data.coords)
   child.data.relative_rotations = props.relative_rotations
   child.data.world_rotations = props.world_rotations
   child.data.lengths = props.lengths


   local new_coords = calculateCoordsFromRotationsAndLengths(false, child.data)
   print(inspect(new_coords))
   print(inspect(child.data.coords))
   child.data.coords = new_coords
end






return mode
