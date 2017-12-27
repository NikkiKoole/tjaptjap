local mode ={}
local utils = require "utils"

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
      if node.dragging then
         local p = getWithID(Hammer.pointers.moved, node.pointerID)
         local moved = Hammer.pointers.moved[p]
         if moved then
            local wx,wy = camera:worldCoords(moved.x-node.dx, moved.y-node.dy)
            local ap = utils.angle( wx, wy, positions[i][1], positions[i][2])
            local dp = utils.distance(positions[i][1], positions[i][2], wx, wy)

            if child.data.relative_rotation then
               ap = ap * -1
               local startAngle = mode:getNestedRotation(i-2)
               ap = ap - startAngle
               ap = ap - math.pi/2
            else
               ap = (math.pi * 2) - (ap + math.pi/2)
            end
            self.child.data.rotations[i] = ap
            --self.child.data.lengths[i] = dp
            self.child.dirty = true
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
      if not isDirty then
         Signal.emit("switch-state", "stage")
      end
   end

end






return mode
