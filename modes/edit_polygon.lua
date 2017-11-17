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
      table.insert(self.handles, {type="vertex", x=self.child.pos.x + p.x, y= self.child.pos.y + p.y, r=32})
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

   if not found then
      Signal.emit("switch-state", "stage")
   end
end



function mode:mousereleased(x, y, button, istouch)
   for i=#self.dragging, 1 ,-1  do
      local it = self.dragging[i]
      if it.touchid == "mouse" then
         if (it.h.type == "vertex") then
            print("released vertex "..it.i.." does it collide with any of its neighbours?")
         end

         if it.h.type == "add_vertex" then
            print("add some vertex somehere!")
            local hx,hy = camera:worldCoords(it.h.x - self.child.pos.x, it.h.y - self.child.pos.y)
            local best = self:getClosestNodes(hx, hy)
            table.insert(self.child.data.points, best.ni, {x=hx, y=hy})
            --self.child.dirty = false
            local shape = shapes.makeShape(self.child)
            self.child.triangles = poly.triangulate(shape)
            --
            mode:makeHandles()
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
         if it.h.type == "add_vertex" then
            print("add some vertex somehere!")
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
   local best_distance = math.huge
   local best_pair = {si=-1, ni=-1}
   for i=1, #self.child.data.points do
      local self_index = i
      local next_index
      if (i == #self.child.data.points) then
         next_index = 1
      else
         next_index = i+1
      end

      local this = self.child.data.points[self_index]
      local next = self.child.data.points[next_index]
      --print(i, x, y, this.x, this.y, next.x, next.y)
      --print(self.child.pos.x, self.child.pos.y)
      local d = utils.distancePointSegment(x, y, this.x , this.y, next.x, next.y)
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


   for i=1, #self.dragging do
      local d = self.dragging[i]
      if (d.h.type ~= "vertex") then
         love.graphics.setColor(200,100,100)
         love.graphics.circle("fill", d.h.x, d.h.y , d.h.r)
         if (d.h.type == "add_vertex") then
            local hx,hy = camera:worldCoords(d.h.x - self.child.pos.x, d.h.y - self.child.pos.y)
            local best = self:getClosestNodes(hx, hy)
            local si = self.child.data.points[best.si]
            local six, siy = camera:cameraCoords(si.x, si.y)
            local ni = self.child.data.points[best.ni]
            local nix, niy = camera:cameraCoords(ni.x, ni.y)

            love.graphics.circle("fill", six + self.child.pos.x, siy+self.child.pos.y, 32)
            love.graphics.circle("fill", nix + self.child.pos.x, niy+self.child.pos.y, 32)
         end
         -- if (d.h.type == "add_cp") then
         --    local hx,hy = camera:worldCoords(d.h.x - self.child.pos.x, d.h.y - self.child.pos.y)
         --    local best = self:getClosestNodes(hx, hy)
         --    local si = self.child.data.points[best.si]
         --    local six, siy = camera:cameraCoords(si.x, si.y)
         --    local ni = self.child.data.points[best.ni]
         --    local nix, niy = camera:cameraCoords(ni.x, ni.y)

         --    love.graphics.circle("fill", six + self.child.pos.x, siy+self.child.pos.y, 32)
         --    love.graphics.circle("fill", nix + self.child.pos.x, niy+self.child.pos.y, 32)
         -- end
      end
   end

   -- draw UI

end






return mode
