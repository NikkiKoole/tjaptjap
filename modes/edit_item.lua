local suit = require 'vendor.suit'
local utils = require "utils"
local mode ={}

-- local ui = {
--    circle = {
--       backdrop = {x=10, y=50, w=200, h=200, r=100, g=100, b=0},
--       buttons = {
--          {value='steps', action=function(v) return math.max(2,v-1) end, x=10, y=50,w=40,h=40,r=150,g=150,b=150},
--          {value='steps', action=function(v) return v+1 end, x=110,y=50,w=40,h=40,r=150,g=150,b=150},
--       },
--       values = {
--          {path='steps', x=60, y=50, r=255, g=255, b=255},
--       },
--       strings = {
--          {str="steps", x=160, y=50, r=255, g=255, b=255},
--       }
--    },
--    rect = {
--       backdrop = {x=10, y=50, w=200, h=200, r=100, g=100, b=0},
--       buttons = {
--          {value='steps', action=function(v) return math.max(2,v-1) end,  x=10, y=50,w=40,h=40,r=150,g=150,b=150},
--          {value='steps', action=function(v) return v+1 end, x=110,y=50,w=40,h=40,r=150,g=150,b=150},
--       },
--       values = {
--          {path='steps', x=60, y=50, r=255, g=255, b=255},
--       },
--       strings = {
--          {str="steps", x=160, y=50, r=255, g=255, b=255},
--       }
--    },
--    star = {
--       backdrop = {x=10, y=50, w=200, h=200, r=100, g=100, b=0},
--       buttons = {
--          {value='sides', action=function(v) return math.max(2,v-1) end, x=10, y=50,w=40,h=40,r=150,g=150,b=150},
--          {value='sides', action=function(v) return v+1 end, x=110,y=50,w=40,h=40,r=150,g=150,b=150},
--       },
--       values = {
--          {path='sides', x=60, y=50, r=255, g=255, b=255},
--       },
--       strings = {
--          {str="sides", x=160, y=50, r=255, g=255, b=255},
--       }
--    },
-- }

local slider = {value = 8, min = 3, max = 24}
--local checkbox = {checked = true, text="stuff"}


function numeric_stepper(child, key)
   local dirty = false
   suit.Label(key, {align="left"},suit.layout:row(60, 10))
   if suit.Button(" - ", suit.layout:col(40, 40)).hit then
      child.data[key] = child.data[key] - 1
      dirty = true
   end
   suit.Label(child.data[key], suit.layout:col(40,40))

   if suit.Button(" + ", suit.layout:col(40, 40)).hit then
      child.data[key] = child.data[key] + 1
      dirty = true
   end

   return dirty
end


function mode:update(dt)
      local child = self.child
      local dirty = false

      local prop = "steps"
      if (child.type == "rect" or child.type == "circle") then
         prop = "steps"
      elseif (child.type== "star") then
         prop="sides"
      end
      suit.layout:reset(10,100)
      suit.layout:padding(10,10)
      suit.Label(child.type, {align="left"}, suit.layout:row(150, 10))
      suit.layout:row()
      suit.Label(prop, {align="left"}, suit.layout:row(150, 10))


      if suit.Slider(slider, suit.layout:row(150,30)).changed then
         child.data[prop] = math.floor(slider.value)
         dirty = true
      end
      suit.Label(child.data[prop], suit.layout:col(50,30))
      suit.layout:left(150)
      dirty = numeric_stepper(child, prop) or dirty

      if dirty then
         slider.value = child.data[prop]
         self.child.dirty = true
         mode:updateHandles()
      end

      -- can i make some hammer button be postiioned in world space?

end

function mode:init()
   self.touches = {}
   self.dragging = {} -- for dragging handlers
end

function mode:updateHandles()
   local child = self.child
   if (child.type == "rect") then

      local rx1,ry1    = utils.rotatePoint(child.pos.x + child.data.w/2, child.pos.y, child.pos.x, child.pos.y, child.rotation)
      local rx2, ry2 = utils.rotatePoint(child.pos.x + child.data.w/2, child.pos.y + child.data.h/2, child.pos.x, child.pos.y, child.rotation)
      local rx3, ry3 = utils.rotatePoint(child.pos.x + child.data.w/2 - child.data.radius, child.pos.y - child.data.h/2, child.pos.x, child.pos.y, child.rotation)

      self.handles = {{
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
      }}
   elseif (child.type == "circle") then
      self.handles = {{
            x=child.pos.x + child.data.radius/1.4,
            y=child.pos.y+ child.data.radius/1.4,
            r=32,
            type="circle-resizer"
      }}
   elseif (child.type == "star") then
      local a = (math.pi*2)/child.data.sides
      local rx,ry      = utils.rotatePoint(child.pos.x + child.data.r1, child.pos.y, child.pos.x, child.pos.y, child.data.a1)
      local rx2,ry2    = utils.rotatePoint(child.pos.x + child.data.r2, child.pos.y, child.pos.x, child.pos.y, child.data.a2)

      self.handles = {{
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
      }}
   else

         --love.errhand("ERROR unknown data type in edit-item: ".. child.data.type)


   end
end

function mode:enter(from,data)
   self.child = data
   mode:updateHandles()
end


function mode:pointerpressed(x,y,id)
   local found = false

   for i=1, #self.handles do
      local h = self.handles[i]
      local hx,hy =camera:cameraCoords(h.x,h.y)
      if (utils.pointInCircle(x,y, hx,hy, 32*camera.scale)) then
         table.insert(self.dragging, {touchid=id, h=self.handles[i], dx=x-hx, dy=y-hy})
         found = true
      end
   end

   local wx, wy = camera:worldCoords(x,y)
   local o = self.child
   local layer_speed = 1.0 + o.pos.z
   local cdx = camera.x - camera.x * layer_speed
   local cdy = camera.y - camera.y * layer_speed

   local hit
--   local ui_item = ui[o.type]

   if o.type == "rect" then
      hit = utils.pointInRect2(wx, wy, o.pos.x + cdx, o.pos.y + cdy, o.data.w, o.data.h  )
      if hit then found = true end
   elseif o.type == "circle" then
      hit = utils.pointInCircle(wx, wy, o.pos.x + cdx, o.pos.y + cdx, o.data.radius)
   elseif o.type == "star" then
      hit = pointInPoly({x=wx,y=wy}, o.triangles)
      --hit = utils.pointInCircle(wx, wy, o.pos.x + cdx, o.pos.y + cdx, math.max(o.data.r1, o.data.r2))
   end
   if hit then found = true end
   --hit = utils.pointInRect(x,y,ui_item.backdrop.x,ui_item.backdrop.y,ui_item.backdrop.w,ui_item.backdrop.h)
   if hit then found = true end

   -- for i=1, #ui_item.buttons do
   --    local b = ui_item.buttons[i]
   --    if (pointInRect(x,y,b.x, b.y, b.w, b.h)) then
   --       self.child.data[b.value] = b.action(self.child.data[b.value])
   --       self.child.dirty = true
   --       mode:updateHandles()
   --    end
   -- end

   if (found == false) then
      Signal.emit("switch-state", "stage")
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

            if it.h.type == "rect-resizer" then
               -- TODO this resize acts in both ways, you would rather want a thing thats stuck to its top left origin
               local dx = nx - self.child.pos.x
               local dy = ny - self.child.pos.y
               local w, h = utils.rotatePoint(dx*2, dy*2, 0,0, -self.child.rotation)
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
            elseif it.h.type == "circle-resizer" then
               local distance = (utils.distance(nx, ny, self.child.pos.x, self.child.pos.y))
               self.child.data.radius = distance
               self.child.dirty = true
            elseif it.h.type == "rect-rotator" then
               self.child.rotation = math.atan2(ny - self.child.pos.y, nx - self.child.pos.x)
               self.child.dirty = true
               mode:updateHandles()
            elseif it.h.type == "rect-radius" then
               local dx = nx - (self.child.pos.x+self.child.data.w/2)
               local dy = ny - (self.child.pos.y+self.child.data.h/2)
               local w, h = utils.rotatePoint(dx, dy, 0,0, -self.child.rotation)
               local r = w*-1
               r = math.max(0, r)
               r = math.min(self.child.data.w/2, r)
               r = math.min(self.child.data.h/2, r)

               self.child.data.radius = r
               self.child.dirty = true
               mode:updateHandles()
            elseif it.h.type == "r1" then
               local distance = (utils.distance(nx, ny, self.child.pos.x, self.child.pos.y))
               local angle = (math.pi/2 +  utils.angle(nx,ny, self.child.pos.x, self.child.pos.y)) * -1
               self.child.data.r1 = distance
               self.child.data.a1 = angle
               self.child.dirty = true
               mode:updateHandles()
            elseif it.h.type == "r2" then
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


function mode:mousemoved(x,y,dx,dy, istouch)
   if (not istouch) then
      self:pointermoved(x,y,'mouse')
   end
end

function mode:touchmoved(id, x, y, dx, dy, pressure)
   self:pointermoved(x,y,id)
end

function mode:mousereleased()
   self.dragging = {}
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

      suit.draw()

   -- local ui_item = ui[self.child.type]
   -- love.graphics.setColor(ui_item.backdrop.r, ui_item.backdrop.g, ui_item.backdrop.b)
   -- love.graphics.rectangle("fill", ui_item.backdrop.x, ui_item.backdrop.y, ui_item.backdrop.w, ui_item.backdrop.h)

   -- for i=1, #ui_item.buttons do
   --    local b = ui_item.buttons[i]
   --    love.graphics.setColor(b.r,b.g,b.b)
   --    love.graphics.rectangle("fill", b.x,b.y,b.w,b.h)
   -- end

   -- for i=1, #ui_item.values do
   --    local v = ui_item.values[i]
   --    love.graphics.setColor(v.r, v.g, v.b)
   --    love.graphics.print(self.child.data[v.path], v.x, v.y  )
   -- end
   -- for i=1, #ui_item.strings do
   --    local s = ui_item.strings[i]
   --    love.graphics.setColor(s.r, s.g, s.b)
   --    love.graphics.print(s.str, s.x, s.y  )
   -- end
end



return mode
