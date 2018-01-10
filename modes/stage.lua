local utils = require "utils"
local shapes = require "shapes"

local mode = {}

function mode:init()
   self.touches = {}
end

function mode:update(dt)
   function dragger(ui)
      local p = getWithID(Hammer.pointers.moved, ui.pointerID)
      local moved = Hammer.pointers.moved[p]
      if moved then
         Hammer:circle("cursor1", 30, {x=moved.x, y=moved.y})
      end
   end
   function releaser(ui, result)
      local p = getWithID(Hammer.pointers.released, ui.pointerID)
      local released = Hammer.pointers.released[p]
      local wx,wy = camera:worldCoords(released.x, released.y)

      result.pos.x = wx
      result.pos.y = wy
      result.world_pos={x=0,y=0,z=0}

      local shape = shapes.makeShape(result)
      result.triangles = poly.triangulate(result.type, shape)
      table.insert(world.children, result)

   end


   Hammer:reset(10,love.graphics.getHeight()- 120)
   local add_shape = Hammer:labelbutton("draw shape", 130,40)
   if add_shape.released then
      self.touches = {}
      Signal.emit("switch-state", "draw-item", {pointerID=id})
   end

   Hammer:pos(10,love.graphics.getHeight()- 60)
   local add_polygon = Hammer:labelbutton("add polygon", 130,40)

   if add_polygon.dragging then
      dragger(add_polygon)
   end
   if add_polygon.released then
      local result = {
         type="polygon",
         pos={x=0, y=0, z=0},
         data={ steps=3,  points={{x=0,y=0}, {cx=100, cy=-100},{cx=200, cy=-100},{cx=300, cy=-100}, {x=200,y=0}, {x=200, y=200}, {x=0, y=250}} }
      }
      releaser(add_polygon, result)
   end
   local add_polyline =    Hammer:labelbutton( "add polyline", 130, 40)
   if add_polyline.dragging then
      dragger(add_polyline)
   end
   if add_polyline.released then
      local result = {
         type="polyline",
         pos={x=0,y=0,z=0},
         data={coords={0,0,-10,-100 , 50, 50, 100,50,10,200}, join="miter", half_width=50, thicknesses={10,20,30,40,50}  }
      }

      releaser(add_polyline, result)
   end

   local add_rope = Hammer:labelbutton( "add rope", 130, 40)
   if add_rope.dragging then
      dragger(add_rope)
   end
   if add_rope.released then
      local result = {
            type="rope",
            pos={x=100,y=100,z=0},
            data={
               join="miter",
               relative_rotation = true,
               rotations={0, 0, 0, 0, 0, 0,0,0,0},
               lengths={120,120,100,100,100,100,100,100 },
               thicknesses={20,50,60,70,70,70,70,60,20},
            }
         }
      releaser(add_rope, result)
   end
   local add_rope2 = Hammer:labelbutton( "add rope2", 130, 40)
   if add_rope2.dragging then
      dragger(add_rope2)
   end
   if add_rope2.released then
      local result = {
         type="rope",
         pos={x=-100,y=100,z=0},
         data={
            join="miter",
            relative_rotation = false,
            rotations={-math.pi/2,-0.8,-0.8,0.8},
            lengths={120,120,100,50},
            thicknesses={40,40,30,20,20},
         }
      }

      releaser(add_rope2, result)
   end


   local add_circle =Hammer:labelbutton( "add circle", 130, 40)
   if add_circle.dragging then
      dragger(add_circle)
   end
   if add_circle.released then
      local result = {type="circle", pos={x=500, y=100, z=0}, data={radius=200, steps=8}}
      releaser(add_circle, result)
   end
   local add_star = Hammer:labelbutton( "add star", 130, 40)
   if add_star.dragging then
      dragger(add_star)
   end
   if add_star.released then
      local result ={type="star", rotation=0.1, pos={x=0, y=300, z=0}, data={sides=8, r1=100, r2=200, a1=0, a2=0}}
      releaser(add_star, result)
   end
   local add_rect =Hammer:labelbutton( "add rect", 130, 40)
   if add_rect.dragging then
      dragger(add_rect)
   end
   if add_rect.released then
      local result = {type="rect", rotation=0, pos={x=300, y=100, z=0}, data={w=200, h=200, radius=50, steps=8}}
      releaser(add_rect, result)
   end
end


function mode:pointerpressed(x, y, id)
   --if not Hammer:isDirty() then


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
      elseif o.type=="polyline" then
         hit = pointInPoly({x=wx,y=wy}, o.triangles)
         --print("polyline?", #o.triangles, hit)

      elseif o.triangles then
         hit = pointInPoly({x=wx,y=wy}, o.triangles)
      else
         print("dont know how to hittest : ", o.type, hit)
      end


      if (hit) then
         self.touches = {}
         Signal.emit("switch-state", "drag-item", {child=world.children[i], pointerID=id})
      end
   end
   --end

end

function mode:mousepressed( x, y, button, istouch )
   if (not istouch) then
      self:pointerpressed(x, y, "mouse")
   end
end

function mode:touchpressed( id, x, y, dx, dy, pressure )
   table.insert(self.touches, {id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})

   if #self.touches == 1 then
      self:pointerpressed(x, y, id)
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
   if not Hammer:isDirty() then

   if (not istouch) then
      if love.mouse.isDown(1) then
         local c,s = math.cos(-camera.rot), math.sin(-camera.rot)
         dx,dy = c*dx - s*dy, s*dx + c*dy
         self.lastdelta = {x=dx, y=dy}
         camera:move(-dx / camera.scale, -dy / camera.scale)
      end
   end
   end

end


function mode:touchmoved( id, x, y, dx, dy, pressure )
   if not Hammer:isDirty() then


      local index = utils.tablefind_id(self.touches, tostring(id))

      if (index > 0) then
         self.touches[index].x = x
         self.touches[index].y = y
         self.touches[index].dx = dx
         self.touches[index].dy = dy
         self.touches[index].pressure = pressure
         --print(dx,dy)
      else
         --print("did this show?")
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
