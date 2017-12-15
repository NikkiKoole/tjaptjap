local mode ={}
local utils = require "utils"


function mode:init()
   self.touches = {}
end


function mode:enter(from,data)
   self.child = data
   self.dragging = {} -- for dragging handlers
   self.handles = {}
   self:makeHandles()
   mode:updateHandles()

end

function mode:draw()
   camera:attach()

   for i=1, #self.handles do
      local h = self.handles[i]

      if (h.type == "rope-point") then
         love.graphics.setColor(255,255,255)
      end

      love.graphics.circle("fill", h.x, h.y , h.r/camera.scale)
   end
   camera:detach()

end

function mode:updateHandles()

   local it = self.child
   local cx, cy = it.pos.x, it.pos.y
   local rotation = 0

   self.handles[1].x = cx
   self.handles[1].y = cy

   --table.insert(self.handles, {type="rope-point", index=1, x=cx, y=cy, r=32})

   for i=1, #it.data.lengths do

      if it.data.relative_rotation then
         rotation = rotation + it.data.rotations[i]
      else
         rotation = it.data.rotations[i]
      end

      cx, cy = utils.moveAtAngle(cx, cy, rotation or -math.pi/2, it.data.lengths[i])
      self.handles[i+1].x = cx
      self.handles[i+1].y = cy

      --table.insert(self.handles, {type="rope-point", index=i+1, x=cx, y=cy, r=32})
   end

end


function mode:makeHandles()
   self.handles = {}
   local it = self.child
   local cx, cy = it.pos.x, it.pos.y
   local rotation = 0

   table.insert(self.handles, {type="rope-point", index=1, x=cx, y=cy, r=32})

   for i=1, #it.data.lengths do

      if it.data.relative_rotation then
         rotation = rotation + it.data.rotations[i]
      else
         rotation = it.data.rotations[i]
      end

      cx, cy = utils.moveAtAngle(cx, cy, rotation or -math.pi/2, it.data.lengths[i])
      table.insert(self.handles, {type="rope-point", index=i+1, x=cx, y=cy, r=32})
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

   function sorter(a, b)
      return a.h.index < b.h.index
   end
   table.sort(self.dragging, sorter)

   if not found then
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

function mode:mousemoved(x,y,dx,dy, istouch)
   if (not istouch) then
      self:pointermoved(x,y,'mouse')
   end
end

function mode:touchmoved(id, x, y, dx, dy, pressure)
   self:pointermoved(x,y,id)
end

function mode:touchreleased( id, x, y, dx, dy, pressure )
   local index = utils.tablefind_id(self.touches, tostring(id))
   table.remove(self.touches, index)

   for i=#self.dragging,1 ,-1  do
      local it = self.dragging[i]
      if it.touchid == id then
         table.remove(self.dragging, i)
      end
   end

end


function mode:update(dt)
end


function mode:getNestedRotation(index)
   local result = 0
   for i=index,1,-1 do
      if self.child.data.rotations[i] then
         result = result + self.child.data.rotations[i]
      end
   end

   return result
end




function mode:pointermoved(x, y, id)
   local child = self.child
   if #self.dragging then
      for i=1, #self.dragging do
         local it = self.dragging[i]
         if it.touchid == id then
            local nx, ny = camera:worldCoords(x - it.dx, y - it.dy)
            it.h.x = nx
            it.h.y = ny
            if (it.h.type == "rope-point") then
               if (it.h.index > 1) then
                  local prev = self.handles[it.h.index-1]
                  local ap = utils.angle( nx, ny, prev.x, prev.y)
                  local dp = utils.distance(prev.x, prev.y, nx, ny)

                  if child.data.relative_rotation then
                     ap = ap * -1
                     local startAngle = mode:getNestedRotation(it.h.index-2)
                     ap = ap - startAngle
                     ap = ap - math.pi/2
                  else
                     ap = (math.pi * 2) - (ap + math.pi/2)
                  end

                  self.child.data.rotations[it.h.index-1] = ap
                  self.child.data.lengths[it.h.index-1] = dp

               else
                  self.child.pos.x = nx
                  self.child.pos.y = ny

               end
                  self.child.dirty = true
                  mode:updateHandles()
            end
         end
      end
   end
end


return mode
