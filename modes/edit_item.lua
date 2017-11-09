local utils = require "utils"

local mode ={}


function rotatePoint(x,y,cx,cy,theta)
   if not theta then return x,y end
   local px = math.cos(theta) * (x-cx) - math.sin(theta) * (y-cy) + cx
   local py = math.sin(theta) * (x-cx) + math.cos(theta) * (y-cy) + cy
   return px,py
end

function mode:update(dt)
end

function mode:init()
   self.touches = {}
   self.dragging = {} -- for dragging handlers
end

function mode:updateHandles()
   local child = self.child
   if (child.type == "rect") then
      local rx1,ry1    = rotatePoint(child.pos.x + child.data.w/2, child.pos.y, child.pos.x, child.pos.y, child.rotation)
      local rx2, ry2 = rotatePoint(child.pos.x + child.data.w/2, child.pos.y + child.data.h/2, child.pos.x, child.pos.y, child.rotation)
      local rx3, ry3 = rotatePoint(child.pos.x + child.data.w/2 - child.data.radius, child.pos.y - child.data.h/2, child.pos.x, child.pos.y, child.rotation)

      self.handles = {
         {
            x=rx1, y=ry1,
            r=32,
            type="rect-rotator"
         },
         {
            x=rx2, y=ry2,
            r=32,
            type="rect-resizer"
         },
         {
            x=rx3, y=ry3,
            r=32,
            type="rect-radius"
         },

      }
   elseif (child.type == "circle") then
      self.handles = {
         {
            x=child.pos.x + child.data.radius/1.4,
            y=child.pos.y+ child.data.radius/1.4,
            r=32,
            type="circle-resizer"
         }
      }
   elseif (child.type == "star") then
      local a = (math.pi*2)/child.data.sides
      local rx,ry      = rotatePoint(child.pos.x + child.data.r1, child.pos.y, child.pos.x, child.pos.y, child.data.a1)
      local rx2,ry2    = rotatePoint(child.pos.x + child.data.r2, child.pos.y, child.pos.x, child.pos.y, child.data.a2)

      self.handles = {
         {
            x=rx,
            y=ry,
            r=32,
            type="r1"
         },
         {
            x=rx2,
            y=ry2,
            r=32,
            type="r2"
         },
      }
   else
      print("ERROR unknown data type in edit-item", data.type)
   end
end


function mode:enter(from,data)
   self.child = data
   mode:updateHandles()

end

function mode:touchpressed( id, x, y, dx, dy, pressure )
   table.insert(self.touches,
                {id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})
   local found = false

   for i=1, #self.handles do
      local h = self.handles[i]
      local hx,hy =camera:cameraCoords(h.x,h.y)
      if (utils.pointInCircle(x,y, hx,hy, 32*camera.scale)) then
         table.insert(self.dragging, {touchid=id, h=self.handles[i]})
         found = true
      end
   end

   local wx, wy = camera:worldCoords(x,y)
   local o = self.child
   local layer_speed = 1.0 + o.pos.z
   local cdx = camera.x - camera.x * layer_speed
   local cdy = camera.y - camera.y * layer_speed

   local hit
   if o.type == "rect" then
      hit = utils.pointInRect2(wx, wy, o.pos.x + cdx, o.pos.y + cdy, o.data.w, o.data.h  )
      if hit then found = true end
            -- some ui crap, note the using of screencoords instead of world coords
      hit = utils.pointInRect(x,y,10,50,200,200)
      if hit then found = true end

      if pointInRect(x,y,10,50,50,50) then
         self.child.data.steps = self.child.data.steps - 1
         self.child.data.steps = math.max(2, self.child.data.steps)
         self.child.dirty = true
         mode:updateHandles()
      end
      if pointInRect(x,y,110,50,50,50) then
         self.child.data.steps = self.child.data.steps + 1
         self.child.dirty = true
         mode:updateHandles()
      end
   end
   if o.type == "circle" then
      hit = utils.pointInCircle(wx, wy, o.pos.x + cdx, o.pos.y + cdx, o.data.radius)
      if hit then found = true end
      -- some ui crap, note the using of screencoords instead of world coords
      hit = utils.pointInRect(x,y,10,50,200,200)
      if hit then found = true end

      if pointInRect(x,y,10,50,50,50) then
         self.child.data.steps = self.child.data.steps - 1
         self.child.data.steps = math.max(2, self.child.data.steps)
         self.child.dirty = true
         mode:updateHandles()
      end
      if pointInRect(x,y,110,50,50,50) then
         self.child.data.steps = self.child.data.steps + 1
         self.child.dirty = true
         mode:updateHandles()

      end


   end
   if o.type == "star" then
      hit = utils.pointInCircle(wx, wy, o.pos.x + cdx, o.pos.y + cdx, math.max(o.data.r1, o.data.r2))
      if hit then found = true end
      -- some ui crap, note the using of screencoords instead of world coords
      hit = utils.pointInRect(x,y,10,50,200,200)
      print("pointin rect 10,50,200,200 ?", hit)
      if hit then found = true end

      if pointInRect(x,y,10,50,50,50) then
         self.child.data.sides = self.child.data.sides - 1
         self.child.data.sides = math.max(2, self.child.data.sides)
         self.child.dirty = true
         mode:updateHandles()

      end
      if pointInRect(x,y,110,50,50,50) then
         self.child.data.sides = self.child.data.sides + 1
         self.child.dirty = true
         mode:updateHandles()

      end
   end
   -- if ui

   if (hit) then
      found = true
   end


   if found == false then
      Signal.emit("switch-state", "stage")
   end

end

function mode:touchmoved(id, x, y, dx, dy, pressure)
   if #self.dragging then
      for i=1, #self.dragging do
         local it = self.dragging[i]
         if it.touchid == id then
            local nx, ny = camera:worldCoords(x, y)
            it.h.x = nx
            it.h.y = ny

            if it.h.type == "rect-resizer" then
               -- TODO this resize acts in both ways, you would rather want a thing thats stuck to its top left origin
               local dx = nx - self.child.pos.x
               local dy = ny - self.child.pos.y
               local w, h = rotatePoint(dx*2, dy*2, 0,0, -self.child.rotation)
               self.child.data.w = math.max(math.abs(w), 0)
               self.child.data.h = math.max(math.abs(h), 0)


               if (self.child.data.radius) then
                  if (self.child.data.radius > (self.child.data.w/2)-1) then
                     self.child.data.radius = (self.child.data.w/2)-1
                     if (self.child.data.radius < 1) then self.child.data.radius = 0 end
                  end
                  if (self.child.data.radius > (self.child.data.h/2)-1) then
                     self.child.data.radius = (self.child.data.h/2)-1
                     if (self.child.data.radius < 1) then self.child.data.radius = 0 end
                  end
               end


               self.child.dirty = true
               mode:updateHandles()
            end
            if it.h.type == "circle-resizer" then
               local distance = (utils.distance(nx, ny, self.child.pos.x, self.child.pos.y))
               self.child.data.radius = distance
               self.child.dirty = true
            end
            if it.h.type == "rect-rotator" then
               self.child.rotation = math.atan2(ny - self.child.pos.y, nx - self.child.pos.x)
               self.child.dirty = true
               mode:updateHandles()
            end
            if it.h.type == "rect-radius" then
               -- there is an issue where if you resize a rounced rectangle the radii could be too big.
               local dx = nx - (self.child.pos.x+self.child.data.w/2)
               local dy = ny - (self.child.pos.y+self.child.data.h/2)
               local w, h = rotatePoint(dx, dy, 0,0, -self.child.rotation)
               local r = w*-1
               r = math.max(0, r)
               r = math.min(self.child.data.w/2, r)
               r = math.min(self.child.data.h/2, r)

               self.child.data.radius = r
               self.child.dirty = true
               mode:updateHandles()
            end
            if it.h.type == "r1" then
               local distance = (utils.distance(nx, ny, self.child.pos.x, self.child.pos.y))
               local angle = (math.pi/2 +  utils.angle(nx,ny, self.child.pos.x, self.child.pos.y)) * -1
               self.child.data.r1 = distance
               self.child.data.a1 = angle
               self.child.dirty = true
               mode:updateHandles()
            end
            if it.h.type == "r2" then
               local distance = (utils.distance(nx, ny, self.child.pos.x, self.child.pos.y))
               local angle = (math.pi/2 +  utils.angle(nx,ny, self.child.pos.x, self.child.pos.y)) * -1
               self.child.data.r2 = distance
               self.child.data.a2 = angle
               self.child.dirty = true
               mode:updateHandles()
            end

         end
      end
   end
end


function mode:touchreleased( id, x, y, dx, dy, pressure )
   local index = utils.tablefind_id(self.touches, tostring(id))
   table.remove(self.touches, index)

   for i=#self.dragging,1 ,-1  do
      local it = self.dragging[i]
      if it.touchid == id then

      end
   end

end

function mode:draw()
   camera:attach()
   love.graphics.setColor(255, 255, 255)

   for i=1, #self.handles do
      local h = self.handles[i]
      love.graphics.circle("fill", h.x, h.y , h.r)
   end
   camera:detach()



   if self.child.type == "star" then
      -- backdrop
      love.graphics.setColor(100,100,0)
      love.graphics.rectangle("fill", 10,50,200,200)
      -- ui for deciding parts
      love.graphics.setColor(155,155,155)
      love.graphics.rectangle("fill", 10,50,40,40)
      love.graphics.rectangle("fill", 10+100,50,40,40)
      love.graphics.setColor(255,255,255)
      love.graphics.print(self.child.data.sides, 50+10, 50  )
      love.graphics.print("sides", 160, 50)
   end
   if self.child.type == "rect" then
      -- backdrop
      love.graphics.setColor(100,100,0)
      love.graphics.rectangle("fill", 10,50,200,200)
      -- ui for deciding parts
      love.graphics.setColor(155,155,155)
      love.graphics.rectangle("fill", 10,50,40,40)
      love.graphics.rectangle("fill", 10+100,50,40,40)
      love.graphics.setColor(255,255,255)
      love.graphics.print(self.child.data.steps, 50+10, 50  )
      love.graphics.print("steps", 160, 50)
   end

   if self.child.type == "circle" then
      -- backdrop
      love.graphics.setColor(100,100,0)
      love.graphics.rectangle("fill", 10,50,200,200)
      -- ui for deciding parts
      love.graphics.setColor(155,155,155)
      love.graphics.rectangle("fill", 10,50,40,40)
      love.graphics.rectangle("fill", 10+100,50,40,40)
      love.graphics.setColor(255,255,255)
      love.graphics.print(self.child.data.steps, 50+10, 50  )
      love.graphics.print("steps", 160, 50)
   end

end


return mode
