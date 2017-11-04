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
      result = makeRect(meta.pos.x, meta.pos.y, meta.data.w, meta.data.h)
   end
   if meta.type == "circle" then
      result = makeCircle(meta.pos.x, meta.pos.y, meta.data.radius)
   end
   if meta.type == "star" then
      result = makeStarPolygon(meta.pos.x, meta.pos.y,
                               meta.data.sides, meta.data.r1, meta.data.r2, meta.data.a1, meta.data.a2)

   end

   return result
end

return {
   makeShape=makeShape
}
