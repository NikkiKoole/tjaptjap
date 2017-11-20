local utils = require "utils"
local shapes = require "shapes"

local mode = {}

function mode:init()
   self.touches = {}
end

function mode:enter(from, data)
   self.child = data
   self.dragging = {} -- for dragging handlers
   self.handles = {}
   self:makeHandles()
end

function mode:makeHandles()
   self.handles = {}
   for i=1, #self.child.data.points do
      local p = self.child.data.points[i]
      if (p.x and p.y) then
         table.insert(self.handles, {type="vertex", x=self.child.pos.x + p.x, y= self.child.pos.y + p.y, r=32})
      elseif (p.cx and p.cy) then
         table.insert(self.handles, {type="cp", x=self.child.pos.x + p.cx, y= self.child.pos.y + p.cy, r=32})
      else
         love.errhand("poly has a point thats neither a normal point nor a control point, dont know what todo with it "..p)
      end
   end
 end


function mode:pointerpressed(x,y,id)
   local found = false
   for i=1, #self.handles do
      local h = self.handles[i]
      local hx,hy = camera:cameraCoords(h.x, h.y)
      if (utils.pointInCircle(x,y, hx,hy, h.r)) then
         table.insert(self.dragging, {touchid=id,  h=self.handles[i], i=i, dx=x-hx, dy=y-hy})
         found = true
         self.lastTouchedIndex = i
      end
   end

   if utils.pointInCircle(x,y, 50, 50, 32) then
      table.insert(self.dragging, {touchid=id,  h={type="add_vertex", x=50, y=50, r=32}, dx=0, dy=0})
      found = true
   end

   if utils.pointInCircle(x,y, 50, 150, 32) then
      table.insert(self.dragging, {touchid=id,  h={type="add_cp", x=50, y=150, r=32}, dx=0, dy=0})
      found = true
   end

   if utils.pointInCircle(x,y, 50, 250, 32) then
      table.insert(self.dragging, {touchid=id,  h={type="remove_last", x=50, y=150, r=32}, dx=0, dy=0})
      found = true
   end

   if not found then
      Signal.emit("switch-state", "stage")
   end
end

function mode:addVertex(x, y)
   local hx,hy = camera:worldCoords(x, y)
   hx = hx - self.child.pos.x
   hy = hy - self.child.pos.y

   local best = self:getClosestNodes(hx, hy)
   table.insert(self.child.data.points, best.ni, {x=hx, y=hy})

   local shape = shapes.makeShape(self.child)
   self.child.triangles = poly.triangulate(shape)
   mode:makeHandles()
end

function mode:addControlPoint(x,y)
   local hx,hy = camera:worldCoords(x, y)
   hx = hx - self.child.pos.x
   hy = hy - self.child.pos.y

   local best = self:getClosestNodes(hx, hy)
   table.insert(self.child.data.points, best.ni, {cx=hx, cy=hy})

   local shape = shapes.makeShape(self.child)
   self.child.triangles = poly.triangulate(shape)
   mode:makeHandles()
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
         self.child.triangles = poly.triangulate(shape)
         mode:makeHandles()
      end
  end
end

function mode:removeLastTouched()
   --self.lastTouchedIndex
   if (self.lastTouchedIndex) then
      table.remove(self.child.data.points, self.lastTouchedIndex)

      local shape = shapes.makeShape(self.child)
      self.child.triangles = poly.triangulate(shape)
      mode:makeHandles()
   end

end

function mode:mousereleased(x, y, button, istouch)
   for i=#self.dragging, 1 ,-1  do
      local it = self.dragging[i]
      if it.touchid == "mouse" then
         if (it.h.type == "vertex") then
            self:removeVertexIfOverlappingWithNextOrPrevious(it)
         end
         if it.h.type == "add_vertex" then
            self:addVertex(it.h.x, it.h.y)
         end
         if it.h.type == "add_cp" then
            self:addControlPoint(it.h.x, it.h.y)
         end

         if it.h.type == "remove_last" then
            self:removeLastTouched()
         end

      end
   end

   self.dragging = {}
end


function mode:touchreleased( id, x, y, dx, dy, pressure )
   local index = utils.tablefind_id(self.touches, tostring(id))
   table.remove(self.touches, index)

   for i=#self.dragging, 1 ,-1  do
      local it = self.dragging[i]
      if it.touchid == id then
         if (it.h.type == "vertex") then
            self:removeVertexIfOverlappingWithNextOrPrevious(it)
         end

         if it.h.type == "add_vertex" then
            self:addVertex(it.h.x, it.h.y)
         end
         if it.h.type == "add_cp" then
            self:addControlPoint(it.h.x, it.h.y)
         end

         if it.h.type == "remove_last" then
            self:removeLastTouched()
         end


      end
   end
end

function mode:mousepressed( x, y, button, istouch )
   if (not istouch) then
      self:pointerpressed(x, y,'mouse')
   end
end

function mode:touchpressed( id, x, y, dx, dy, pressure )
   table.insert(self.touches, {id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})
   self:pointerpressed(x,y,id)
end

function mode:pointermoved(x, y, id)
   if #self.dragging then
      for i=1, #self.dragging do
         local it = self.dragging[i]
         if it.touchid == id then
            local nx, ny = camera:worldCoords(x - it.dx, y - it.dy)
            it.h.x = nx
            it.h.y = ny
            if (it.h.type == "vertex") then
               self.child.data.points[it.i].x = nx - self.child.pos.x
               self.child.data.points[it.i].y = ny - self.child.pos.y
               self.child.dirty = true
            elseif (it.h.type == "add_vertex") then
               it.h.x = x
               it.h.y = y
            elseif (it.h.type == "add_cp") then
               it.h.x = x
               it.h.y = y
            elseif (it.h.type =="cp") then
               self.child.data.points[it.i].cx = nx - self.child.pos.x
               self.child.data.points[it.i].cy = ny - self.child.pos.y
               self.child.dirty = true
            else

            end
         end
      end
   end
end



function mode:mousemoved(x,y,dx,dy, istouch)
   if (not istouch) then
      self:pointermoved(x,y,'mouse')
   end
end

function mode:touchmoved(id, x, y, dx, dy, pressure)
   self:pointermoved(x,y,id)
end

function mode:update()
   if self.child.dirty then
      self.child.dirty = false
      local shape = shapes.makeShape(self.child)
      self.child.triangles = poly.triangulate(shape)
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


function mode:draw()
   camera:attach()
   love.graphics.setColor(255,255,255)
   for i=1, #self.handles do
      local h = self.handles[i]
      if (h.type == "vertex") then love.graphics.setColor(255,255,255) end
      if (h.type == "cp")     then love.graphics.setColor(0  ,255,255) end

      love.graphics.circle("fill", h.x, h.y , h.r/camera.scale)
   end
   camera:detach()

   love.graphics.setColor(100,100,100)
   love.graphics.rectangle("fill", 10, 10, 100, 200)

   love.graphics.setColor(200,100,100)
   love.graphics.circle("fill", 50, 50, 32)
   love.graphics.setColor(255,255,255)
   love.graphics.print("add vertex", 20, 40)

   love.graphics.setColor(200,100,100)
   love.graphics.circle("fill", 50, 150, 32)
   love.graphics.setColor(255,255,255)
   love.graphics.print("add bezier point", 20, 140)

   love.graphics.setColor(200,100,100)
   love.graphics.circle("fill", 50, 250, 32)
   love.graphics.setColor(255,255,255)
   love.graphics.print("remove last touched", 20, 240)

   for i=1, #self.dragging do
      local d = self.dragging[i]
      if (d.h.type ~= "vertex") then

         if (d.h.type == "add_vertex" or d.h.type == "add_cp") then
            love.graphics.setColor(200,100,100)
            love.graphics.circle("fill", d.h.x, d.h.y , d.h.r)

            local hx,hy = camera:worldCoords(d.h.x, d.h.y)
            hx = hx - self.child.pos.x
            hy = hy - self.child.pos.y

            local best = self:getClosestNodes(hx, hy)
            local si = self.child.data.points[best.si]
            local six, siy = camera:cameraCoords((si.x or si.cx) + self.child.pos.x, (si.y or si.cy) + self.child.pos.y)
            local ni = self.child.data.points[best.ni]
            local nix, niy = camera:cameraCoords((ni.x or ni.cx) + self.child.pos.x, (ni.y or ni.cy) + self.child.pos.y)

            love.graphics.circle("fill", six, siy, 32)
            love.graphics.circle("fill", nix, niy, 32)
         end
      end
   end
end

return mode
