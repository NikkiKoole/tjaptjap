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
   self.updatecount = 0
end


function mode:addVertex(x, y)
   local hx,hy = camera:worldCoords(x, y)
   hx = hx - self.child.pos.x
   hy = hy - self.child.pos.y

   local best = self:getClosestNodes(hx, hy)
   table.insert(self.child.data.points, best.ni, {x=hx, y=hy})

   local shape = shapes.makeShape(self.child)
   local p = poly.triangulate(self.child.type, shape)
   self.child.triangles = p

end

function mode:addControlPoint(x,y)
   local hx,hy = camera:worldCoords(x, y)
   hx = hx - self.child.pos.x
   hy = hy - self.child.pos.y

   local best = self:getClosestNodes(hx, hy)
   table.insert(self.child.data.points, best.ni, {cx=hx, cy=hy})

   local shape = shapes.makeShape(self.child)
   self.child.triangles = poly.triangulate(self.child.type, shape)

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
      local shape = shapes.makeShape(self.child)
      self.child.triangles = poly.triangulate(self.child.type, shape)
   end
end

function mode:getClosestNodes(x, y)
   local points = self.child.data.points
   local best_distance = math.huge
   local best_pair = {si=-1, ni=-1}
   for i=1, #points do

      local self_index = i
      local next_index = i + 1

      if (i == #points) then
         next_index = 1
      end

      local this = points[self_index]
      local next = points[next_index]
      local d = utils.distancePointSegment(x, y, this.x or this.cx , this.y or this.cy, next.x or next.cx, next.y or next.cy)

      if (d < best_distance) then
         best_distance = d
         best_pair = {si=self_index, ni = next_index}
      end
   end
   return best_pair
end


function mode:update()
   if self.child.dirty then
      self.child.dirty = false
      local shape = shapes.makeShape(self.child)
      self.child.triangles = poly.triangulate(self.child.type, shape)
   end


   Hammer:reset(0,0)



   for i=1, #self.child.data.points do

      local point = self.child.data.points[i]
      local cx2, cy2 = camera:cameraCoords(
         (point.x or point.cx) + self.child.pos.x,
         (point.y or point.cy) + self.child.pos.y)
      local color
      if point.x and point.y then
         color={0,100,100}
      else
         color={200,100,100}
      end


      local button = Hammer:rectangle("poly-handle"..i, 60, 60,
                                      {x=cx2-30,
                                       y=cy2-30,
                                       color=color})

      if button.pressed then
         self.lastTouchedIndex = i
      end

      if button.dragging then
         self.lastTouchedIndex = i

         local p = getWithID(Hammer.pointers.moved, button.pointerID)
         local moved = Hammer.pointers.moved[p]
         if moved then
            local wx,wy = camera:worldCoords(moved.x, moved.y)
            wx = wx - button.dx/camera.scale - self.child.pos.x
            wy = wy - button.dy/camera.scale - self.child.pos.y

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
   Hammer:label("triscount", "#tris:"..#(self.child.triangles), 100, 20)
   Hammer:ret()
   Hammer:label("addvid", "add vertex", 100, 20)
   local add_vertex = Hammer:rectangle("drag1", 80,80)

   if add_vertex.dragging then
      local p = getWithID(Hammer.pointers.moved, add_vertex.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
         local wx,wy = camera:worldCoords(moved.x, moved.y)
         local best =mode:getClosestNodes(wx,wy)
         local si = self.child.data.points[best.si]
         local ni = self.child.data.points[best.ni]
         local x2,y2 = camera:cameraCoords(
            (si.x or si.cx) + self.child.pos.x,
            (si.y or si.cy) + self.child.pos.y )

         Hammer:circle("si", 10, {x=x2, y=y2})
         x2,y2 = camera:cameraCoords(
            (ni.x or ni.cx) + self.child.pos.x,
            (ni.y or ni.cy) + self.child.pos.y )


         Hammer:circle("ni", 10, {x=x2, y=y2})
      end
   end
   if add_vertex.enddrag then
      local p = getWithID(Hammer.pointers.released,
                          add_vertex.pointerID)
      local released = Hammer.pointers.released[p]

      self:addVertex(released.x, released.y)
   end

   Hammer:ret()
   Hammer:ret()
   Hammer:label("addcp", "bezier point", 100, 20)

   local add_cp = Hammer:rectangle("drag2", 80,80)
   if add_cp.dragging then
      local p = getWithID(Hammer.pointers.moved, add_cp.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor2", 30, {x=moved.x, y=moved.y})
         local wx,wy = camera:worldCoords(moved.x, moved.y)
         local best =mode:getClosestNodes(wx,wy)
         local si = self.child.data.points[best.si]
         local ni = self.child.data.points[best.ni]
         local x2,y2 = camera:cameraCoords(
            (si.x or si.cx) + self.child.pos.x,
            (si.y or si.cy) + self.child.pos.y )

         Hammer:circle("si", 10, {x=x2, y=y2})
         x2,y2 = camera:cameraCoords(
            (ni.x or ni.cx) + self.child.pos.x,
            (ni.y or ni.cy) + self.child.pos.y )

         Hammer:circle("ni", 10, {x=x2, y=y2})
      end
   end
   if add_cp.enddrag then
      local p = getWithID(Hammer.pointers.released,
                          add_cp.pointerID)
      local released = Hammer.pointers.released[p]

      self:addControlPoint(released.x, released.y)
   end
   Hammer:ret()
   Hammer:ret()
   Hammer:label("delete", "delete last active node", 200, 20)
   local del_node = Hammer:rectangle("del_last_active", 40,40)
   if del_node.released then
      mode:removeLastTouched()
      self.lastTouchedIndex = false
   end
   Hammer:ret()
   Hammer:label("quit", "exit mode", 200, 20)
   Hammer:ret()

   local exit_node = Hammer:rectangle("exit_mode", 60,60)
   if exit_node.released then
      Signal.emit("switch-state", "stage")
   end



end


return mode
