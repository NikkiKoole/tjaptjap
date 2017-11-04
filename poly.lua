
function split_poly(poly, intersection)
   local biggestIndex = math.max(intersection.i1, intersection.i2)
   local smallestIndex = math.min(intersection.i1, intersection.i2)
   local wrap = {}
   local bb = biggestIndex
   while bb ~= smallestIndex do
      bb = bb + 2
      if bb > #poly-1 then
         bb = 1

      end
      table.insert(wrap, poly[bb])
      table.insert(wrap, poly[bb+1])

   end
   table.insert(wrap, intersection.x)
   table.insert(wrap, intersection.y)


   local back = {}
   local bk = biggestIndex
   while bk ~= smallestIndex do
      table.insert(back, poly[bk])
      table.insert(back, poly[bk+1])

      bk = bk -2

   end
   table.insert(back, intersection.x)
   table.insert(back, intersection.y)
   return wrap, back
end



function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end


function get_line_intersection(p0_x, p0_y, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)
   local s1_x, s1_y, s2_x, s2_y
   local s1_x = p1_x - p0_x
   local s1_y = p1_y - p0_y
   local s2_x = p3_x - p2_x
   local s2_y = p3_y - p2_y

   local s, t
   s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y)
   t = ( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y)

   if (s >= 0 and s <= 1 and t >= 0 and t <= 1) then
      --print("s and t : ",s,t)
      return p0_x + (t * s1_x), p0_y + (t * s1_y)
   end

   return 0
end


function get_collisions(poly)
   local collisions = {}

   for outeri=1, #poly,2 do
      local ax=poly[outeri]
      local ay=poly[outeri+1]
      local ni= outeri+2
      if outeri==#poly-1 then ni=1 end
      local bx=poly[ni]
      local by=poly[ni+1]

      for inneri=1, #poly,2 do
         local cx=poly[inneri]
         local cy=poly[inneri+1]
         local ni= inneri+2
         if inneri==#poly-1 then ni=1 end
         local dx=poly[ni]
         local dy=poly[ni+1]

         if inneri ~= outeri then
            local result, opt = get_line_intersection(ax,ay,bx,by,cx,cy,dx,dy)
            if (ax == cx and ay == cy) or (ax == dx and ay == dy) or
            (bx == cx and by == cy) or (bx == dx and by == dy) then
              -- print("share corner")
            else
               if result ~= 0 then
                  local col = {i1=outeri, i2=inneri, x=result, y=opt }

                  local alreadyfound = false
                  for i=1, #collisions do
                     if (collisions[i].i1 == inneri and collisions[i].i2 == outeri) then
                        alreadyfound=true
                     else
                     end
                  end

                  if not alreadyfound then
                     table.insert(collisions, col)
                     --print(col.i1, col.i2, col.x, col.y)
                  end
               end
            end
         end

      end
   end
   return collisions
end


function decompose_complex_poly(poly, result)
   local intersections = get_collisions(poly)
   if #intersections == 0 then
      result = TableConcat(result, {poly})
   end
   if #intersections > 1 then
      local p1, p2 = split_poly(poly, intersections[1])
      local p1c, p2c = get_collisions(p1),get_collisions(p2)
      if (#p1c > 0) then
         result = decompose_complex_poly(p1, result)
      else
         result = TableConcat(result, {p1})
      end

       if (#p2c > 0) then
         result = decompose_complex_poly(p2, result)
      else
         result = TableConcat(result, {p2})
      end
   end
   if #intersections == 1 then
      local p1, p2 = split_poly(poly, intersections[1])
      result = TableConcat(result, {p1})
      result = TableConcat(result, {p2})
   end

   return result
end

function getCentroid(triangle)
   local x = (triangle[1] + triangle[3] + triangle[5])/3
   local y = (triangle[2] + triangle[4] + triangle[6])/3
   return x,y
end

function isPointInPath(x,y, poly)
   local num = #poly
   local j = num - 1
   local c = false
   for i=1, #poly,2 do
      if ((poly[i+1] > y) ~= (poly[j+1] > y)) and
      (x < (poly[j+0] - poly[i+0]) * (y - poly[i+1]) / (poly[j+1] - poly[i+1]) + poly[i+0]) then
          c = not c
      end
      j = i
   end
   return c
end


function triangulate(poly)
   local result = {}
   -- first split a polygon into simpler parts
   local polys = decompose_complex_poly(poly, {})
   for i=1 ,#polys do
      local p = polys[i]
      local triangles = love.math.triangulate(p)
      for j=1, #triangles do
         local t = triangles[j]
         local cx, cy = getCentroid(t)
         if isPointInPath(cx,cy, p) then
            table.insert(result, t)
         end
      end
   end
   return result
end


return {
   triangulate=triangulate
}
