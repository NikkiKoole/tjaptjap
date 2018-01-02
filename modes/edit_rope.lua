local mode ={}
local utils = require "utils"

local thickness_value = {min=1, max=100, value=50}
local last_active_node_index = 0

function mode:enter(from,data)
   self.child = data
end


function mode:getClosestNode(x, y, points)

   local best_distance = math.huge
   local index = -1
   local insertIndex = -1
   --local best_pair = {si=-1, ni=-1}
   for i=1, #points do
      local d = utils.distance(x,y,points[i][1],points[i][2])
      if d < best_distance then
         index = i
         best_distance = d
      end
   end

   -- Figure out if the current x,y is closer to the next index then the current index is.

   if index < #points then
      local d1 = utils.distance(x,y,points[index+1][1],points[index+1][2])
      local d2 = utils.distance(points[index][1],points[index][2],points[index+1][1],points[index+1][2])
      if d1 < d2 then
         insertIndex = index
      else
         insertIndex = index -1
      end
   elseif index == #points then
      local d1 = utils.distance(x,y,points[index-1][1],points[index-1][2])
      local d2 = utils.distance(points[index][1],points[index][2],points[index-1][1],points[index-1][2])
      if d1 < d2 then
         --print("insert before")
         insertIndex = index-1

      else
         --print("insert after")
         insertIndex = index

      end
   end

   return points[index], insertIndex
end



function mode:getNestedRotation(index)
   local result = 0
   for i=index,1,-1 do
      if self.child.data.rotations[i] then
         result = result + self.child.data.rotations[i]
      end
   end

   return result
end


local pointdragging = {}
function getDraggingByPointerID(pointerID)
   for i=1, #pointdragging do
      if pointdragging[i].pointerID == pointerID then
         return pointdragging[i].draggingID
      end
   end
   return -1
end
function getIndexOfPointerID(pointerID)
   for i=1, #pointdragging do
      if pointdragging[i].pointerID == pointerID then
         return i
      end
   end
   return -1
end


function mode:update(dt)
   local child = self.child
   Hammer:reset(0,0)
   local color={200,100,100}

   local rotation   = 0
   local cx, cy     = child.pos.x, child.pos.y
   local rx,ry      = camera:cameraCoords(cx, cy)
   local root       = Hammer:rectangle( "root", 30, 30,{x=rx-15, y=ry-15, color=color})
   local positions  = {{cx,cy}}


   if root.dragging then
      local p = getWithID(Hammer.pointers.moved, root.pointerID)
      local moved = Hammer.pointers.moved[p]

      if moved then
         local wx,wy = camera:worldCoords(moved.x-root.dx, moved.y-root.dy)
         child.pos.x = wx
         child.pos.y = wy
         child.dirty = true
      end
   end
   if root.startpress then
      last_active_node_index = 1
      thickness_value.value = child.data.thicknesses[last_active_node_index] or 0
   end


   for i=1, #child.data.lengths do
      if child.data.relative_rotation then
         rotation = rotation + child.data.rotations[i]
      else
         rotation = child.data.rotations[i]
      end

      cx, cy = utils.moveAtAngle(cx, cy, rotation or -math.pi/2, child.data.lengths[i])
      table.insert(positions, {cx,cy})
      local rx,ry      = camera:cameraCoords(cx, cy)
      local node = Hammer:rectangle( "node"..i, 30, 30,{x=rx-15, y=ry-15, color=color})
      if node.startpress then
         last_active_node_index = i + 1
         thickness_value.value = child.data.thicknesses[last_active_node_index] or 0
      end
      if node.released then

         local index = getIndexOfPointerID(node.pointerID)
         if index >-1 then
            table.remove(pointdragging,index)
         else
            --print("COULDNT FIND INDEX TO RELEASE POINTER")
         end
         --print("currently dragging "..#pointdragging.." draggables")

      end

      if node.dragging then
         local draggingID = getDraggingByPointerID(node.pointerID)
         if draggingID == -1 then
            table.insert(pointdragging, {pointerID=node.pointerID, draggingID=node.id})
         end

         if draggingID ~= -1 and draggingID ~= node.id then

         else
            local p = getWithID(Hammer.pointers.moved, node.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local wx,wy = camera:worldCoords(moved.x-node.dx, moved.y-node.dy)
               local ap = utils.angle( wx, wy, positions[i][1], positions[i][2])
               local dp = utils.distance(positions[i][1], positions[i][2], wx, wy)

               if child.data.relative_rotation then
                  ap = ap * -1
                  local startAngle = mode:getNestedRotation(i-1)
                  ap = ap - startAngle
                  ap = ap - math.pi/2
               else
                  ap = (math.pi * 2) - (ap + math.pi/2)
               end
               self.child.data.rotations[i] = ap
               self.child.data.lengths[i] = dp
               self.child.dirty = true
            end
         end

      end


   end

   -------------------------------
   -------------------------------
   -- have a dropdown where you can select the joint type [none, join, bevel]

   Hammer:pos(20,300)
   Hammer:ret()
   local none  = Hammer:labelbutton("none", 60,30)
   if none.startpress then
      print("startpress ")
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


   ------------------------------------------------
   -----------------
   -- a slider where you set the thickness of  the last active node
   -- how to deal with multiple ?

   if last_active_node_index > 0 then
      Hammer:ret()
      --thickness_value.value = self.child.data.thicknesses[last_active_node_index]
      Hammer:label("thickness node", "thickness: "..math.floor(thickness_value.value), 150, 30)
      Hammer:ret()

      local value = thickness_value.value

      local thickness_slider = Hammer:slider("thickness", 200,40, thickness_value)

      if thickness_value.value ~= value then
         self.child.data.thicknesses[last_active_node_index] = math.floor(thickness_value.value)
         self.child.dirty = true
      end
   end

   Hammer:ret()

   --- drag new vertexes into the rope, like edit-polygon does
   local add_vertex = Hammer:labelbutton("add vertex", 120,40)
   if add_vertex.dragging then
      local p = getWithID(Hammer.pointers.moved, add_vertex.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
         local wx,wy = camera:worldCoords(moved.x, moved.y)
         local si= mode:getClosestNode(wx,wy, positions)
         local x2,y2 = camera:cameraCoords(si[1], si[2])
         Hammer:circle("si", 10, {x=x2, y=y2})
         --x2,y2 = camera:cameraCoords(ni[1], ni[2])
         --Hammer:circle("ni", 10, {x=x2, y=y2})
      end
   end

   if add_vertex.enddrag then
      local p = getWithID(Hammer.pointers.released, add_vertex.pointerID)
      local released = Hammer.pointers.released[p]
      if released then
         local wx,wy = camera:worldCoords(released.x, released.y)
         local si, insertIndex = mode:getClosestNode(wx,wy, positions)
         --print("add vertex somehewere!", wx, wy, "at index: ", insertIndex)
         if insertIndex > 0 and insertIndex < #positions then
            local d = utils.distance(positions[insertIndex][1],positions[insertIndex][2],wx,wy)
            local a = utils.angle(wx,wy,positions[insertIndex][1],positions[insertIndex][2])

            if not self.child.data.relative_rotation then
               a = (math.pi*2)- (a + math.pi/2)
            else
               a = a * -1
               local startAngle = mode:getNestedRotation(insertIndex-1)
               a = a - startAngle
               a = a - math.pi/2
            end


            self.child.data.lengths[insertIndex] = d
            self.child.data.rotations[insertIndex] = a

            local d2 = utils.distance(positions[insertIndex+1][1],positions[insertIndex+1][2],wx,wy)
            local a2 = utils.angle(positions[insertIndex+1][1],positions[insertIndex+1][2],wx,wy)
            if not self.child.data.relative_rotation then
               a2 = (math.pi*2)- (a2 + math.pi/2)
            else
               a2 = a2 * -1
               local startAngle = mode:getNestedRotation(insertIndex)
               a2 = a2 - startAngle
               a2 = a2 - math.pi/2
            end

            table.insert(self.child.data.lengths, insertIndex+1, d2)
            table.insert(self.child.data.rotations, insertIndex+1, a2)
            table.insert(self.child.data.thicknesses, insertIndex+1, (self.child.data.thicknesses[insertIndex] + self.child.data.thicknesses[insertIndex])/2)

            self.child.dirty = true
         else
            if insertIndex == 0 then
               self.child.pos.x = wx
               self.child.pos.y = wy
               local d2 = utils.distance(positions[1][1],positions[1][2],wx,wy)
               local a2 = utils.angle(positions[1][1],positions[1][2],wx,wy)
               if not self.child.data.relative_rotation then
                  a2 = (math.pi*2)- (a2 + math.pi/2)
               else
                  local rot = self.child.data.rotations[1]
                  local startAngle = rot--mode:getNestedRotation(0)

                  a2 =  (math.pi*2)- a2
                  a2 = a2 - startAngle
                  a2 = a2 - math.pi/2
                  print(rot, a2, rot-a2)
                  self.child.data.rotations[1] = rot - a2
                  print("this is a bit buggy ;(")
               end



               table.insert(self.child.data.lengths, 1, d2)
               table.insert(self.child.data.rotations, 1, a2)
               table.insert(self.child.data.thicknesses, 1, 10)

               self.child.dirty = true
            end
            if insertIndex == #positions then
               -- dont understand why this works without adding a new item ??

               local d = utils.distance(positions[insertIndex][1],positions[insertIndex][2],wx,wy)
               local a = utils.angle(wx,wy,positions[insertIndex][1],positions[insertIndex][2])

               self.child.data.lengths[insertIndex] = d
               self.child.data.rotations[insertIndex] = (math.pi*2)- (a + math.pi/2)


               self.child.dirty = true

            end



         end



      end

   end
   local del_node = Hammer:labelbutton("delete last", 140,40)
   if del_node.released then
      if last_active_node_index > 0 then
         local index = last_active_node_index --((last_active_node_index-1)/2)+1
         table.remove(self.child.data.thicknesses, index)
         table.remove(self.child.data.lengths, index)
         table.remove(self.child.data.rotations, index)
         self.child.dirty=true
         last_active_node_index = 0
      end

      --mode:removeLastTouched()
      --self.lastTouchedIndex = false
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



   -- if clicked outside any of the UI elements or the actual shape go back to the stage mode
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
