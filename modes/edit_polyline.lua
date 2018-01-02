local mode = {}
local utils = require "utils"

local thickness_value = {min=1, max=100, value=50}
local last_active_node_index = 0


-- local pointdragging = {}
-- function getDraggingByPointerID(pointerID)
--    for i=1, #pointdragging do
--       if pointdragging[i].pointerID == pointerID then
--          return pointdragging[i].draggingID
--       end
--    end
--    return -1
-- end
-- function getIndexOfPointerID(pointerID)
--    for i=1, #pointdragging do
--       if pointdragging[i].pointerID == pointerID then
--          return i
--       end
--    end
--    return -1
-- end

function mode:getClosestNode(x,y,coords)
   -- TODO this is completely broken, this whole function

   local best_distance = math.huge
   local index = -1

   --local x = x - self.child.pos.x
   --local y = y - self.child.pos.y

   for i=1, #coords, 2 do
      local d = utils.distance(x,y,coords[i], coords[i+1])
      if d < best_distance then
         index = i
         best_distance = d
      end
   end

   if index < #coords-1 then
      local d1 = utils.distance(x, y,
                                coords[index+2],coords[index+3])
      local d2 = utils.distance(coords[index],coords[index+1],coords[index+2],coords[index+3])
      if d1 < d2 then
         index = index + 2
--         print("added 2")
      else
  --       print("not added 2")

      end

   else
      local d1 = utils.distance(x,y,coords[index-2],coords[index-1])
      local d2 = utils.distance(coords[index],coords[index+1],coords[index-2],coords[index-1])
      if d1 > d2 then
         index = index + 2
      end
   end

   return {x=coords[index], y=coords[index+1]}, index
end



function mode:enter(from,data)
   self.child = data
end

function mode:update(dt)
   local c = self.child
   local color={200,100,100}

   Hammer:reset(0,0)


   local coords = c.data.coords
   for i=1, #coords, 2 do
      local rx,ry      = camera:cameraCoords(coords[i] + c.pos.x, coords[i+1] + c.pos.y)
      local node = Hammer:rectangle( "node"..i, 30, 30,{x=rx-15, y=ry-15, color=color})

      if node.dragging then
         local p = getWithID(Hammer.pointers.moved, node.pointerID)
         local moved = Hammer.pointers.moved[p]
         if moved then
            last_active_node_index = i

            local wx,wy = camera:worldCoords(moved.x - (node.dx), moved.y - (node.dy))
            self.child.data.coords[i]   = wx - c.pos.x
            self.child.data.coords[i+1] = wy - c.pos.y
            self.child.dirty = true
         end

      end
      if node.startpress then
         last_active_node_index = i
         local index = ((i-1)/2)+1
         if self.child.data.thicknesses then
            thickness_value.value = self.child.data.thicknesses[index] or 0
         end
      end

   end

   Hammer:pos(20,300)


   Hammer:ret()
   local none  = Hammer:labelbutton("none", 100,30)
   if none.startpress then
      self.child.data.join = "none"
      self.child.dirty = true
   end
   local miter = Hammer:labelbutton("miter", 100,30)
   if miter.startpress then
      self.child.data.join = "miter"
      self.child.dirty = true
   end
   local bevel = Hammer:labelbutton("bevel", 100,30)
   if bevel.startpress then
      self.child.data.join = "bevel"
      self.child.dirty = true
   end
   Hammer:ret()



   --- drag new vertexes into the rope, like edit-polygon does
   local add_vertex = Hammer:labelbutton("add vertex", 100,60)
   if add_vertex.dragging then
      local p = getWithID(Hammer.pointers.moved, add_vertex.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
         --local wx,wy = camera:worldCoords(moved.x, moved.y)
         --local si, insertIndex = mode:getClosestNode(wx,wy, self.child.data.coords)

      end
   end

   if add_vertex.enddrag then
      local p = getWithID(Hammer.pointers.released, add_vertex.pointerID)
      local released = Hammer.pointers.released[p]
      if released then
         local wx,wy = camera:worldCoords(released.x-self.child.pos.x, released.y-self.child.pos.y)
         local si, insertIndex = mode:getClosestNode(wx,wy, self.child.data.coords)
         local index = ((insertIndex-1)/2)+1
         table.insert(self.child.data.coords, insertIndex, wy)
         table.insert(self.child.data.coords, insertIndex, wx)
         table.insert(self.child.data.thicknesses, index, 20)
         print("insert thickness at index: ", index)
         self.child.dirty=true
         for i=1, #self.child.data.thicknesses do
            print(i..", "..self.child.data.thicknesses[i])
         end
         last_active_node_index = 0
      end
   end
   Hammer:ret()
   if last_active_node_index > 0 then
      Hammer:ret()
      --thickness_value.value = self.child.data.thicknesses[last_active_node_index]
      Hammer:label("thickness node", "thickness: "..thickness_value.value, 150, 30)
      Hammer:ret()

      local value = thickness_value.value

      local thickness_slider = Hammer:slider("thickness", 200,40, thickness_value)

      if thickness_value.value ~= value then
         local index = ((last_active_node_index-1)/2)+1
         self.child.data.thicknesses[index] = math.floor(thickness_value.value)
         self.child.dirty = true
      end
   end

   Hammer:ret()

   local del_node = Hammer:labelbutton("delete last", 140,40)
   if del_node.released then
      if last_active_node_index > 0 then
         local index = ((last_active_node_index-1)/2)+1
         if self.child.data.thicknesses then
            table.remove(self.child.data.thicknesses, index)
         end

         table.remove(self.child.data.coords, last_active_node_index)
         table.remove(self.child.data.coords, last_active_node_index)
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




   if #Hammer.pointers.pressed == 1 then
      local isDirty = false
      for i=1, #Hammer.drawables do
         local it = Hammer.drawables[i]
         if it.over or it.pressed or it.dragging then
            isDirty = true
            print("hammer dirty")
         end
      end

      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)
      local hit = pointInPoly({x=wx,y=wy}, self.child.triangles)
      if hit then
         isDirty = true
         print("point in poly dirty")

      end

      if not isDirty then
         Signal.emit("switch-state", "stage")
      end
   end

end


return mode
