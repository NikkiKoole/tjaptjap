polyline = require 'polyline'
local utils = require "utils"


function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function makeCirclePart(cx, cy, radius, angle1, angle2, step)
   if not step then step = (math.pi/32) end

   local result = {}
   local x, y
   for angle=angle1, angle2, step do
      x = cx + radius * math.cos(angle)
      y = cy + radius * math.sin(angle)
      table.insert(result, x)
      table.insert(result, y)
   end

   return result
end


function makeSimpleRect(cx, cy, w, h)
   local result = {}
   local w2 = w/2
   local h2 = h/2

   table.insert(result, cx + (w2))
   table.insert(result, cy - (h2))

   table.insert(result, cx + (w2))
   table.insert(result, cy + (h2))

   table.insert(result, cx - (w2))
   table.insert(result, cy + (h2))

   table.insert(result, cx - (w2))
   table.insert(result, cy - (h2))

   return result

end


function makeRoundedRect(cx,cy, w, h, radius, step)
   local result = {}
   if not step then step = 32 end
   step = math.pi/step
   local w2 = w/2
   local h2 = h/2
   local rounded

   w2 = math.max(w2, 1)
   h2 = math.max(h2, 1)

   --print(radius, w2, h2)
   -- we go clockwise starting at the top left

   -- inserting cx and cy so the polygn will be oriented around its center.
   --table.insert(result, cx)
   --table.insert(result, cy)

   rounded = makeCirclePart(cx - (w2-radius), cy - (h2-radius), radius, -math.pi, -math.pi/2, step)
   TableConcat(result, rounded)

  -- table.insert(result, cx + (w2-radius))
  -- table.insert(result, cy - (h2))

   rounded = makeCirclePart(cx + (w2-radius), cy - (h2-radius), radius, -math.pi/2, 0, step)
   TableConcat(result, rounded)

   --table.insert(result, cx + (w2))
   --table.insert(result, cy + (h2-radius))

   rounded = makeCirclePart(cx + (w2-radius), cy + (h2-radius), radius, 0, math.pi/2, step)
   TableConcat(result, rounded)

   --table.insert(result, cx - (w2-radius))
   --table.insert(result, cy + (h2))

   rounded = makeCirclePart(cx - (w2-radius), cy + (h2-radius), radius, math.pi/2, math.pi,  step)
   TableConcat(result, rounded)

   --table.insert(result, cx - (w2))
   --table.insert(result, cy - (h2-radius))

   return result
end



function makeRect(cx, cy, w, h)
   local result = {}
   local w2, h2 = w/2, h/2

   --table.insert(result, cx)
   --table.insert(result, cy)


   table.insert(result, cx-w2)
   table.insert(result, cy-h2)
   table.insert(result, cx+w2)
   table.insert(result, cy-h2)
   table.insert(result, cx+w2)
   table.insert(result, cy+h2)
   table.insert(result, cx-w2)
   table.insert(result, cy+h2)

   --table.insert(result, cx-w2)
   --table.insert(result, cy-h2)
   return result
end


function makeCircle(cx, cy, radius, step)
   step = math.pi/step

   if not step then step = (math.pi/16) end
   local result = {}
   local x, y

   table.insert(result, cx)
   table.insert(result, cy)

   for angle=0, (math.pi * 2), step do
      x = cx + radius * math.cos(angle)
      y = cy + radius * math.sin(angle)
      table.insert(result, x)
      table.insert(result, y)
   end

   x = cx + radius * math.cos(math.pi * 2)
   y = cy + radius * math.sin(math.pi * 2)
   table.insert(result, x)
   table.insert(result, y)


   return result
end
function makeStarPolygon(cx, cy, sides, r1, r2, a1, a2)
   local result = {}
   local steps = sides*2
   local anglestep = (math.pi * 2) / steps
   local angle1 = a1
   local a = 0 --the angle my point points towards
   local r = 0 -- the radius, or distance of my point

   --table.insert(result, cx)
   --table.insert(result, cy)

   for i=1, steps do
      if i %  2 == 0 then
         r = r1
         a = angle1
      else
         r = r2
         a = angle1 + a2
      end

      table.insert(result, cx + r * math.cos(a))
      table.insert(result, cy + r * math.sin(a))

      angle1 = angle1 + anglestep
   end

   --table.insert(result, cx + r2 * math.cos(angle1 + a2))
   --table.insert(result, cy + r2 * math.sin(angle1 + a2))

   return result
end






function makeCustomPolygon(x,y, points, steps)
   local result = {}

   local i = 1

   while i < #points+1 do
      local p = points[i]

      if (p.x and p.y) then
         table.insert(result, x + p.x)
         table.insert(result, y + p.y)
         i = i +1
      else
         local prev_index = i - 1
         if i <= 1 then prev_index = #points end
         -- print(prev_index, #points)
         local array = {(points[prev_index].x or points[prev_index].cx)  + x,
                        (points[prev_index].y or points[prev_index].cy) + y}

         local j = i
         local next = points[j]
         while (not (next.x and next.y)) do
            table.insert(array, x + next.cx)
            table.insert(array, y + next.cy)
            j = j + 1
            next = points[j]
         end



         i = i + ((#array-2)/2)
         table.insert(array, points[j].x + x)
         table.insert(array, points[j].y + y)
         curve = love.math.newBezierCurve(array)
         local curve_points = curve:render(steps)

         table.remove(curve_points, #curve_points)
         table.remove(curve_points, #curve_points)
         table.remove(curve_points, 1)
         table.remove(curve_points, 1)

         TableConcat(result, curve_points)
      end
   end

   return result
end

function makeSmartLine(x,y, data, meta)
   -- The idea here is to either use the given coords to calculate all other values OR
   -- use either rotations or world_rotations and lengths
   local result = {}

   if #data.coords > 0 then

      -- first (given the original coords) i calculate all other arrays

      -- first the rotation to the next one
      local world_rotation = 0
      for i=1, #data.coords-2, 2 do
         local thisX, thisY = data.coords[i+0],data.coords[i+1]
         local nextX, nextY = data.coords[i+2], data.coords[i+3]
         local a = utils.angle(thisX, thisY, nextX, nextY)
         local d = utils.distance(thisX, thisY, nextX, nextY)

         --print( thisX, thisY, nextX, nextY, "=>", a, a+world_rotation, d )
         world_rotation = world_rotation + a
      end
   else
      if data.use_relative_rotation and #data.relative_rotations > 0 then
         data.coords = utils.calculateCoordsFromRotationsAndLengths(true, data, x, y)
      elseif not data.use_relative_rotation and #data.world_rotations > 0 then
         data.coords = utils.calculateCoordsFromRotationsAndLengths(false, data, x, y)
      else

         print("Did i get here? How do i fix this", inspect(meta))
      end

      -- hope we have some other data then
   end

   local props = calculateAllPropsFromCoords(data.coords)
   data.relative_rotations = props.relative_rotations
   data.world_rotations    = props.world_rotations


   local newcoords = {}
   for i=1, #data.coords, 2 do
      newcoords[i] = data.coords[i] + x
      newcoords[i+1] = data.coords[i+1] + y
   end

--   if data.id then print("id: ", data.id) end
   assert(#newcoords >= 4)
   local vertices, indices, draw_mode = polyline(data.join, newcoords, data.thicknesses, 1, false)
   result = {vertices=vertices, indices=indices, draw_mode=draw_mode,type="smartline"}

   return result
end




function makeMesh3d(x,y,data)
   local result = {}
   result.width = data.width
   result.height = data.height
   result.cx = x
   result.cy = y
   if not data.cells then
      data.cells = {}
      for i=1, data.width+1 do
         data.cells[i] = {}
         for j=1, data.height+1 do
            data.cells[i][j]= {
               x=i*data.cellwidth ,
               y=j*data.cellheight, z=0}
         end
      end
   end

   result.cells = data.cells
   result.type="mesh3d"
   return result
end

function makeShape(meta)
   local result = {}

   if meta.type == "rect" then
      result = makeRoundedRect(meta.pos.x, meta.pos.y, meta.data.w, meta.data.h, meta.data.radius or 0, meta.data.steps or 8)
   elseif meta.type == "simplerect" then
      result = makeSimpleRect(meta.pos.x, meta.pos.y, meta.data.w, meta.data.h)
   elseif meta.type == "circle" then
      result = makeCircle(meta.pos.x, meta.pos.y, meta.data.radius, meta.data.steps or 10)
   elseif meta.type == "star" then
      result = makeStarPolygon(meta.pos.x, meta.pos.y, meta.data.sides, meta.data.r1, meta.data.r2, meta.data.a1, meta.data.a2)
   elseif meta.type == "polygon" then
      result = makeCustomPolygon(meta.pos.x, meta.pos.y, meta.data.points, 2 or meta.data.steps)
   elseif meta.type == "smartline" then
      result = makeSmartLine(meta.pos.x, meta.pos.y, meta.data, meta)
   elseif meta.type == "mesh3d" then
      result = makeMesh3d(meta.pos.x, meta.pos.y, meta.data)
   else
      love.errhand("Unknown shape type: "..meta.type)
   end


   return result
end

function getShapeBBox(shape)
   local min={x=math.huge,y=math.huge}
   local max={x=-math.huge,y=-math.huge}

   local x,y
   for i=1, #shape, 2 do
      x = shape[i + 0]
      y = shape[i + 1]
      if math.min(x, min.x) == x then min.x = x end
      if math.min(y, min.y) == y then min.y = y end
      if math.max(x, max.x) == x then max.x = x end
      if math.max(y, max.y) == y then max.y = y end
   end

   return min.x,min.y,max.x,max.y
end

function transformShape(tx,ty, shape, meta)
   local result = {}

   if meta.type == "smartline" then

      for i=1, #shape.vertices do
         local it = shape.vertices[i]
         shape.vertices[i][1] = it[1] + tx
         shape.vertices[i][2] = it[2] + ty
      end
      return shape

      --result = makeSmartLine(tx,ty, meta.data)
      --return result
   elseif meta.type == "mesh3d" then
      result = makeMesh3d(tx,ty, meta.data)
      return result
   end

   for i=1, #shape, 2 do
      result[i+0] = shape[i+0] + tx
      result[i+1] = shape[i+1] + ty
   end
   return result
end



function rotateShape(cx, cy, shape, theta)
   --print(inspect(shape))
   local result = {}
   local x,y,nx,ny
   local costheta = math.cos(theta)
   local sintheta = math.sin(theta)

   if shape.type and shape.type == "smartline" then
      for i=1, #shape.vertices do
         local it = shape.vertices[i]
         x = it[1]
         y = it[2]
         nx = costheta * (x-cx) - sintheta * (y-cy) + cx
         ny = sintheta * (x-cx) + costheta * (y-cy) + cy
         shape.vertices[i][1] = nx
         shape.vertices[i][2] = ny
      end
      return shape
   else
      for i=1, #shape, 2 do
         x = shape[i +0]
         y = shape[i+1]
         nx = costheta * (x-cx) - sintheta * (y-cy) + cx
         ny = sintheta * (x-cx) + costheta * (y-cy) + cy
         result[i+0] = nx
         result[i+1] = ny
      end
   end

   return result
end

function scaleShape(shape, xfactor, yfactor)
   assert(shape)
   if shape.type == "smartline" then
      print("Uh oh scaling a rope cant go right")
   end

   local result = {}
   local x,y,nx,ny


   for i=1, #shape, 2 do
      result[i] = shape[i] * xfactor
      result[i+1] = shape[i+1] * yfactor

   end
   return result
end

function patchShape(shape)
   -- some shapes have double coords clean that
   local result = {}
   for i=1, #shape, 2 do
      table.insert(result, shape[i])
      table.insert(result, shape[i+1])
   end
   return result
end


return {
   makeShape=makeShape,
   rotateShape=rotateShape,
   scaleShape=scaleShape,
   getShapeBBox=getShapeBBox,
   transformShape=transformShape,
   patchShape=patchShape
}
