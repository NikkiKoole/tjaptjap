local utils = require "utils"
local mode = {}

function mode:init()
   self.touches = {}
end

function mode:pointerpressed(x, y)
   local wx, wy = camera:worldCoords(x,y)
   for i, o in ipairs(world.children) do

      local layer_speed = 1.0 + o.pos.z
      local cdx = camera.x - camera.x * layer_speed
      local cdy = camera.y - camera.y * layer_speed
      local hit = false

      if o.type == "circle" then
         hit = utils.pointInCircle(wx, wy, o.pos.x + cdx, o.pos.y + cdx, o.data.radius)
      elseif o.type == "star" then
         hit = pointInPoly({x=wx,y=wy}, o.triangles)
      elseif o.type=="rect" then
         hit = utils.pointInRect2(wx, wy, o.pos.x + cdx,   o.pos.y + cdy, o.data.w, o.data.h )
      elseif o.type=="polygon" then
         hit = pointInPoly({x=wx,y=wy}, o.triangles)
      else
         hit = pointInPoly({x=wx,y=wy}, o.triangles)

         print("dont know how to hittest : ", o.type)
      end


      if (hit) then
         self.touches = {}
         Signal.emit("switch-state", "drag-item", world.children[i])
      end
   end
end

function mode:mousepressed( x, y, button, istouch )
   if (not istouch) then
      self:pointerpressed(x, y)
   end
end

function mode:touchpressed( id, x, y, dx, dy, pressure )
   table.insert(self.touches, {id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})

   if #self.touches == 1 then
      self:pointerpressed(x, y)
   elseif #self.touches == 2 then
      self.initial_distance = utils.distance(
         self.touches[1].x,
         self.touches[1].y,
         self.touches[2].x,
         self.touches[2].y
      )
      self.initial_angle =  math.atan2(
         self.touches[1].x - self.touches[2].x,
         self.touches[1].y - self.touches[2].y
      )
      self.initial_center =  {
         x=utils.center(self.touches[1].x, self.touches[2].x),
         y=utils.center(self.touches[1].y, self.touches[2].y)
      }
   else
   end
end

function mode:touchreleased( id, x, y, dx, dy, pressure )
   --if self.lastdelta then end
   local index = utils.tablefind_id(self.touches, tostring(id))
   table.remove(self.touches, index)
end

function mode:wheelmoved(x,y)
   self.lastdelta = {x=0, y=0}
   local new_center = {x=love.mouse.getX(), y= love.mouse.getY()}
   local scale_diff = (y/10)
   zoom(scale_diff, new_center)
end

function mode:mousemoved(x, y, dx, dy, istouch)
   if (not istouch) then
      if love.mouse.isDown(1) then
         local c,s = math.cos(-camera.rot), math.sin(-camera.rot)
         dx,dy = c*dx - s*dy, s*dx + c*dy
         self.lastdelta = {x=dx, y=dy}
         camera:move(-dx / camera.scale, -dy / camera.scale)
      end
   end
end


function mode:touchmoved( id, x, y, dx, dy, pressure )
   local index = utils.tablefind_id(self.touches, tostring(id))

   if (index > 0) then
      self.touches[index].x = x
      self.touches[index].y = y
      self.touches[index].dx = dx
      self.touches[index].dy = dy
      self.touches[index].pressure = pressure
   end

   if #self.touches == 1 then
      local c,s = math.cos(-camera.rot), math.sin(-camera.rot)
      dx,dy = c*dx - s*dy, s*dx + c*dy
      self.lastdelta = {x=dx, y=dy}
      camera:move(-dx / camera.scale, -dy / camera.scale)
   elseif #self.touches == 2 then
      self.lastdelta = {x=0, y=0}

      local new_center = {
         x=utils.center(self.touches[1].x, self.touches[2].x),
         y=utils.center(self.touches[1].y, self.touches[2].y)
      }

      --scale
      local d = utils.distance(
         self.touches[1].x, self.touches[1].y,
         self.touches[2].x, self.touches[2].y
      )

      local scale_diff = (d - self.initial_distance) / self.initial_distance

      zoom(scale_diff, new_center)
      self.initial_distance = d

      -- translate
      local dx2 = self.initial_center.x - new_center.x
      local dy2 = self.initial_center.y - new_center.y
      self.initial_center = new_center

      local c,s = math.cos(-camera.rot), math.sin(-camera.rot)
      dx2, dy2 = c*dx2 - s*dy2, s*dx2 + c*dy2
      camera:move(dx2 / camera.scale, dy2 / camera.scale)
   else
   end
   --updatePolygons(camera)
   --clamp_camera()

end

function zoom(scaleDiff, center)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local new_x = center.x - w/2
    local new_y = center.y - h/2
    local offsetX = new_x/(camera.scale * (1 + scaleDiff)) - new_x/camera.scale
    local offsetY = new_y/(camera.scale * (1 + scaleDiff)) - new_y/camera.scale

    camera:move(-offsetX, -offsetY )
    camera:zoom(1 + scaleDiff)
    --clamp_camera()
end


function clamp_camera()
   -- somehow i need to take screensize more into account.
   local w,h = love.graphics.getWidth(), love.graphics.getHeight()
   local offsetX,offsetY = (w/camera.scale)/2, (h/camera.scale)/2
   local clamp_style = "fancy"
   local x,y,zoom
   local minzoomX = w/(bounds.br.x - bounds.tl.x)
   local minzoomY = h/(bounds.br.y - bounds.tl.y)
   local minzoom = math.max(minzoomX, minzoomY)

   if (clamp_style == "fancy") then
      zoom = utils.clamp(camera.scale, minzoom, math.huge)
      camera.scale = zoom
      offsetX,offsetY = (w/camera.scale)/2, (h/camera.scale)/2
      x = utils.clamp(camera.x, bounds.tl.x + offsetX, bounds.br.x - offsetX)
      y = utils.clamp(camera.y, bounds.tl.y + offsetY, bounds.br.y - offsetY)
   else
      -- less fancy clamping
      x = utils.clamp(camera.x, bounds.tl.x, bounds.br.x)
      y = utils.clamp(camera.y, bounds.tl.y, bounds.br.y)
   end

   camera.x = x
   camera.y = y
end

return mode
