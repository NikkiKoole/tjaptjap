local utils = require "utils"

local shapes = require "shapes"
local mode = {}





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
      local shape = shapes.makeShape(self.child)
      self.child.triangles = poly.triangulate(self.child.type, shape)
   end
end

function mode:getClosestNodes(x, y)
   local points = self.child.data.points
   local best_distance = math.huge
   local si=-1
   local ni=-1
   --local best_pair = {si=-1, ni=-1}
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
         --best_pair = {si=self_index, ni = next_index}
         si = self_index
         ni = next_index
      end
   end
   return si,ni
end




function mode:update()
   local child = self.child

   -- TODO optimize, make bbox a prop on shapes, now we need to calculate it everyframe
   local shape = shapes.makeShape(child)

   local bbminx, bbminy, bbmaxx, bbmaxy= shapes.getShapeBBox(shape)

   Hammer:reset(10,200)

   Hammer:pos(0,0)


   local p = child.pivot

   local rx2, ry2 = camera:cameraCoords(
      child.world_trans(p and p.x or 0, p and p.y or 0)
   )
   local pivot = Hammer:rectangle( "pivot", 30, 30,{x=rx2-15, y=ry2-15, color=color})
   makePivotBehaviour(pivot, child)






   local rx1, ry1 = camera:cameraCoords(
      child.world_trans(  (p and p.x or 0) + (bbmaxx-bbminx)/2 ,  (p and p.y or 0))
   )
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


      -- local cx2, cy2 = camera:cameraCoords(
      --    (point.x or point.cx) + child.pos.x,
      --    (point.y or point.cy) + child.pos.y)
      local color

      if point.x and point.y then
         color={0,100,100}
      else
         color={200,100,100}
      end


      local button = Hammer:rectangle( "poly-handle"..i, 30, 30,
                                       {x=cx2-15, y=cy2-15, color=color})

      if button.pressed then
         self.lastTouchedIndex = i
      end

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




   Hammer:pos(10,300)
   local add_shape = Hammer:labelbutton("draw shape", 130,40)
   if add_shape.released then
      self.touches = {}
      if not self.child.children then self.child.children = {} end
      Signal.emit("switch-state", "draw-item", {pointerID=id, parent=self.child})
   end

   Hammer:label("triscount", "#tris:"..#(self.child.triangles), 100, 20)
   Hammer:ret()
   local add_vertex = Hammer:labelbutton("add vertex", 120,40)
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
   local add_cp = Hammer:labelbutton("bezier", 120,40)
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

   local del_node = Hammer:labelbutton("delete last", 120,40)
   if del_node.released then
      mode:removeLastTouched()
      self.lastTouchedIndex = false
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
      local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)

      local isDirty = Hammer:isDirty()

      if not isDirty then
      -- if hit test children (if any) try and drag them
         if self.child.children then
            for i=1,#self.child.children do
               local hit = pointInPoly({x=wx,y=wy}, self.child.children[i].triangles)
               if hit then
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


return mode
