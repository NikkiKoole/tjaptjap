local utils = require "utils"
local mode ={}

local star_value = {value = 8, min = 3, max = 24}
local circle_value = {value = 8, min = 2, max = 24}

function mode:enter(from,data)
   self.child = data
end


function mode:update(dt)
      local child = self.child

      if child.type == "rect" then
         local rx1, ry1 = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.w/2, child.pos.y,
                                                                child.pos.x, child.pos.y, child.rotation))

         local color = {200,100,100}
         Hammer:reset(0,0)

         local rx3, ry3 = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.w/2 - child.data.radius, child.pos.y - child.data.h/2,
                                                                child.pos.x, child.pos.y, child.rotation))


         local rx2, ry2 = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.w/2, child.pos.y + child.data.h/2,
                                                                child.pos.x, child.pos.y, child.rotation))
         local resizer = Hammer:rectangle( "resizer", 30, 30,{x=rx2-15, y=ry2-15, color=color})

         if resizer.dragging then
            local p = getWithID(Hammer.pointers.moved, resizer.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local dx, dy = camera:worldCoords(moved.x - child.pos.x -resizer.dx, moved.y - child.pos.y -resizer.dy)
               local w, h = utils.rotatePoint(dx*2, dy*2, 0,0, -child.rotation)
               self.child.data.w = math.max(math.abs(w), 0)
               self.child.data.h = math.max(math.abs(h), 0)

               if (child.data.radius) then
                  if (child.data.radius > (child.data.w/2)-1) then
                     self.child.data.radius = (child.data.w/2)-1
                     if (child.data.radius < 1) then child.data.radius = 0 end
                  end
                  if (child.data.radius > (child.data.h/2)-1) then
                     self.child.data.radius = (child.data.h/2)-1
                     if (child.data.radius < 1) then self.child.data.radius = 0 end
                  end
               end

               self.child.dirty = true

            end
         end


         local radius = Hammer:rectangle( "radius", 30, 30,{x=rx3-15, y=ry3-15, color=color})

         if radius.dragging then
            local p = getWithID(Hammer.pointers.moved, radius.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local dx, dy = camera:worldCoords(moved.x - (child.pos.x+child.data.w/2) - radius.dx,
                                                 moved.y - (child.pos.y+child.data.h/2) - radius.dy)
               local w, h = utils.rotatePoint(dx, dy, 0,0, -self.child.rotation)
               local r = w*-1
               r = math.max(0, r)
               r = math.min(child.data.w/2, r)
               r = math.min(child.data.h/2, r)
               self.child.data.radius = r
               self.child.dirty = true
            end
         end

         local rotator = Hammer:rectangle( "rotator", 30, 30,{x=rx1-15, y=ry1-15, color=color})
         if rotator.dragging then
            local p = getWithID(Hammer.pointers.moved, rotator.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local wx,wy = camera:worldCoords(moved.x-rotator.dx, moved.y-rotator.dy)

               self.child.rotation = math.atan2(wy - child.pos.y, wx - child.pos.x)
               self.child.dirty = true

            end
         end



      end


      if child.type == "circle" then
         local rx,ry      = camera:cameraCoords(child.pos.x + child.data.radius/1.4,
                                                child.pos.y + child.data.radius/1.4)
         local color = {200,100,100}

         Hammer:reset(10,300)

         local radius = Hammer:rectangle( "circle_radius_handle", 30, 30,{x=rx-15, y=ry-15, color=color})
         if radius.dragging then
            local p = getWithID(Hammer.pointers.moved, radius.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local wx,wy = camera:worldCoords(moved.x-radius.dx, moved.y-radius.dy)
               local distance = (utils.distance(wx, wy, self.child.pos.x, self.child.pos.y))
               self.child.data.radius = distance
               self.child.dirty = true

            end

         end


         local value = circle_value.value
         local sides = Hammer:slider("steps", 200,40, circle_value)
         if circle_value.value ~= value then
            self.child.data.steps = math.floor(circle_value.value)
            self.child.dirty = true
         end
      end


      if child.type == "star" then
         local rx,ry      = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.r1, child.pos.y, child.pos.x, child.pos.y, child.data.a1 ))
         local rx2,ry2    = camera:cameraCoords(utils.rotatePoint(child.pos.x + child.data.r2, child.pos.y, child.pos.x, child.pos.y, child.data.a2))
         local color = {200,100,100}

         Hammer:reset(0,0)
         local r1 = Hammer:rectangle( "star_r1_handle", 30, 30,{x=rx-15, y=ry-15, color=color})
         if r1.dragging then
            local p = getWithID(Hammer.pointers.moved, r1.pointerID)
            local moved = Hammer.pointers.moved[p]
            if moved then
               local wx,wy = camera:worldCoords(moved.x-r1.dx, moved.y-r1.dy)
               --wx = wx - r1.dx/camera.scale - child.pos.x
               --wy = wy - r1.dy/camera.scale - child.pos.y
               local distance = (utils.distance(wx, wy, self.child.pos.x, self.child.pos.y))
               local angle = (math.pi/2 +  utils.angle(wx,wy, self.child.pos.x, self.child.pos.y)) * -1
               self.child.data.r1 = distance
               self.child.data.a1 = angle
               self.child.dirty = true

            end
         end

         local r2 = Hammer:rectangle( "star_r2_handle", 30, 30,{x=rx2-15, y=ry2-15, color=color})
         if r2.dragging then
            local p = getWithID(Hammer.pointers.moved, r2.pointerID)
            local moved = Hammer.pointers.moved[p]
            if moved then
               local wx,wy = camera:worldCoords(moved.x-r2.dx, moved.y-r2.dy)
               --wx = wx - r1.dx/camera.scale - child.pos.x
               --wy = wy - r1.dy/camera.scale - child.pos.y
               local distance = (utils.distance(wx, wy, self.child.pos.x, self.child.pos.y))
               local angle = (math.pi/2 +  utils.angle(wx,wy, self.child.pos.x, self.child.pos.y)) * -1
               self.child.data.r2 = distance
               self.child.data.a2 = angle
               self.child.dirty = true

            end
         end
         Hammer:pos(10,300)
         local value = star_value.value
         local sides = Hammer:slider("sides", 200,40, star_value)
         if star_value.value ~= value then
            self.child.data.sides = math.floor(star_value.value)
            self.child.dirty = true

         end

         --if sides.dragged then
         --end
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
