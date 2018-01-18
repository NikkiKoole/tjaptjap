local utils = require "utils"
local shapes = require "shapes"
local a = require "vendor.affine"

local mode ={}

local star_value = {value = 8, min = 3, max = 24}
local circle_value = {value = 8, min = 2, max = 24}

function mode:enter(from,data)
   self.child = data
end


function mode:update(dt)
      local child = self.child

      if child.type == "rect" then


         local color = {200,100,100}
         Hammer:reset(0,0)

         local resizer_x, resizer_y = camera:cameraCoords(
            child.world_trans(child.data.w/2, child.data.h/2)
         )
         local resizer = Hammer:rectangle( "resizer", 30, 30,{x=resizer_x-15, y=resizer_y-15, color=color})
         if resizer.dragging then
            local p = getWithID(Hammer.pointers.moved, resizer.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local wx,wy = camera:worldCoords(moved.x-resizer.dx, moved.y-resizer.dy)
               wx,wy = child.inverse(wx,wy)
               self.child.data.w = wx*2
               self.child.data.h = wy*2
               self.child.dirty = true
            end
         end





         local radius_x, radius_y = camera:cameraCoords(
            child.world_trans(child.data.w/2 - child.data.radius, -child.data.h/2)
         )
         local radius = Hammer:rectangle( "radius", 30, 30,{x=radius_x-15, y=radius_y-15, color=color})
         if radius.dragging then
            local p = getWithID(Hammer.pointers.moved, radius.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local wx,wy = camera:worldCoords(moved.x-radius.dx, moved.y-radius.dy)
               wx,wy = child.inverse(wx,wy)
               self.child.data.radius = self.child.data.w/2 - wx
               self.child.dirty = true
            end
         end


         local p = child.pivot
         local pivot_x, pivot_y = camera:cameraCoords(
            child.world_trans(p and p.x or 0, p and p.y or 0)
         )
         local pivot = Hammer:rectangle( "pivot", 30, 30,{x=pivot_x-15, y=pivot_y-15, color=color})
         if pivot.dragging then
            local p = getWithID(Hammer.pointers.moved, pivot.pointerID)
            local moved = Hammer.pointers.moved[p]

            if moved then
               local wx,wy = camera:worldCoords(moved.x-pivot.dx, moved.y-pivot.dy)
               wx,wy = child.inverse(wx,wy)

               if not child.pivot then
                  child.pivot = {x=0,y=0}
               end


               local dx = wx - child.pivot.x
               local dy = wy - child.pivot.y

               child.pivot.x = wx
               child.pivot.y = wy

               child.pos.x = child.pos.x + dx
               child.pos.y = child.pos.y + dy
               child.dirty = true
            end
         end




         local shape = shapes.makeShape(child)
         local bbminx, bbminy, bbmaxx, bbmaxy= shapes.getShapeBBox(shape)

         local rx1, ry1 = camera:cameraCoords(
            child.world_trans(  (p and p.x or 0) + (child.data.w)/2 ,  (p and p.y or 0))
         )
         rx2, ry2 = camera:cameraCoords(
            child.world_trans(p and p.x or 0, p and p.y or 0)
         )

         local rotator = Hammer:rectangle( "rotator", 30, 30,{x=rx1-15, y=ry1-15, color=color})

         if rotator.dragging  then
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
         local isDirty = false
         for i=1, #Hammer.drawables do
            local it = Hammer.drawables[i]
            if it.over or it.pressed or it.dragging then
               isDirty = true
            end
         end
         if not isDirty then
      -- if hit test children (if any) try and drag them
            local wx, wy = camera:worldCoords(Hammer.pointers.pressed[1].x, Hammer.pointers.pressed[1].y)

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
