local mode ={}
local utils = require "utils"

local thickness_value = {min=1, max=100, value=50}
local last_active_node_index = 0

function mode:enter(from,data)
   self.child = data
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

--local draggingID = nil

-- a pointer can only be dragging one item at a time
-- {pointerID=x, draggingID=x}

local pointdragging = {}
function getDraggingByPointerID(pointerID)
   for i=1, #pointdragging do
      if pointdragging[i].pointerID == pointerID then
         --print(pointerID, pointdragging[i].draggingID)
         return pointdragging[i].draggingID
      end

      --print(pointdragging[i].pointerID, pointdragging[i].draggingID)
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
         end

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
   Hammer:label("jointype label1", "join:", 150, 30)
   Hammer:ret()
   Hammer:label("jointype label2", "none/miter/bevel", 150, 30)

   Hammer:ret()
   local none  = Hammer:rectangle("none button", 30,30)
   if none.startpress then
      self.child.data.join = "none"
      self.child.dirty = true
   end
   local miter = Hammer:rectangle("miter button", 30,30)
   if miter.startpress then
      self.child.data.join = "miter"
      self.child.dirty = true
   end
   local bevel = Hammer:rectangle("bevel button", 30,30)
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
      Hammer:label("thickness node", "thickness: "..thickness_value.value, 150, 30)
      Hammer:ret()

      local value = thickness_value.value

      local thickness_slider = Hammer:slider("thickness", 200,40, thickness_value)

      if thickness_value.value ~= value then
         self.child.data.thicknesses[last_active_node_index] = math.floor(thickness_value.value)
         self.child.dirty = true
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
