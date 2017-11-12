

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

   x = cx + radius * math.cos(angle2)
   y = cy + radius * math.sin(angle2)
   table.insert(result, x)
   table.insert(result, y)

   return result
end

function makeRoundedRect(cx,cy, w, h, radius, step)
   step = math.pi/step
   if not step then step = (math.pi/32) end
   local w2 = w/2
   local h2 = h/2
   local rounded
   local result = {}

   w2 = math.max(w2, 1)
   h2 = math.max(h2, 1)

   --print(radius, w2, h2)
   -- we go clockwise starting at the top left

   -- inserting cx and cy so the polygn will be oriented around its center.
   --table.insert(result, cx)
   --table.insert(result, cy)

   rounded = makeCirclePart(cx - (w2-radius), cy - (h2-radius), radius, -math.pi, -math.pi/2, step)
   TableConcat(result, rounded)

   table.insert(result, cx + (w2-radius))
   table.insert(result, cy - (h2))

   rounded = makeCirclePart(cx + (w2-radius), cy - (h2-radius), radius, -math.pi/2, 0, step)
   TableConcat(result, rounded)

   table.insert(result, cx + (w2))
   table.insert(result, cy + (h2-radius))

   rounded = makeCirclePart(cx + (w2-radius), cy + (h2-radius), radius, 0, math.pi/2, step)
   TableConcat(result, rounded)

   table.insert(result, cx - (w2-radius))
   table.insert(result, cy + (h2))

   rounded = makeCirclePart(cx - (w2-radius), cy + (h2-radius), radius, math.pi/2, math.pi,  step)
   TableConcat(result, rounded)

   table.insert(result, cx - (w2))
   table.insert(result, cy - (h2-radius))



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

   return result
end


function makeShape(meta)
   local result = {}
--   print(meta.type, meta.pos, meta.data)
   if meta.type == "rect" then

      result = makeRoundedRect(meta.pos.x, meta.pos.y, meta.data.w, meta.data.h, meta.data.radius or 0, meta.data.steps or 8)
   end
   if meta.type == "circle" then
      result = makeCircle(meta.pos.x, meta.pos.y, meta.data.radius, meta.data.steps or 10)
   end
   if meta.type == "star" then
      result = makeStarPolygon(meta.pos.x, meta.pos.y,
                               meta.data.sides, meta.data.r1, meta.data.r2, meta.data.a1, meta.data.a2)

   end

   return result
end

function rotateShape(cx, cy, shape, theta)
   local result = {}

   local costheta = math.cos(theta)
   local sintheta = math.sin(theta)
   local x,y,nx,ny

   for i=1, #shape, 2 do
      x = shape[i +0]
      y = shape[i+1]
      nx = costheta * (x-cx) - sintheta * (y-cy) + cx
      ny = sintheta * (x-cx) + costheta * (y-cy) + cy
      result[i+0] = nx
      result[i+1] = ny
   end

   return result
end


return {
   makeShape=makeShape,
   rotateShape=rotateShape
}
