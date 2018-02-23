
function gaussian(mean, stdev)
   -- TODO get rid of returning a function, just return the result already
   local y2
   local use_last = false
   return function()
      local y1
      if (use_last) then
         y1 = y2
         use_last = false
      else
         local x1=0
         local x2=0
         local w=0
         x1 = 2.0 * love.math.random() - 1.0
         x2 = 2.0 * love.math.random() - 1.0
         w  = x1 * x1 + x2 * x2
         while( w >= 1.0) do
             x1 = 2.0 * love.math.random() - 1.0
             x2 = 2.0 * love.math.random() - 1.0
             w  = x1 * x1 + x2 * x2
         end
          w = math.sqrt((-2.0 * math.log(w))/w)
          y1 = x1 * w
          y2 = x2 * w
          use_last = true
      end
      local retval = mean + stdev * y1
      if (retval > 0) then return retval end
      return -retval
   end
end

function generatePolygon(ctrX, ctrY, aveRadius, irregularity, spikeyness, numVerts)
   irregularity = clip( irregularity, 0,1 ) * 2 * math.pi / numVerts
   spikeyness = clip( spikeyness, 0,1 ) * aveRadius
   angleSteps = {}
   lower = (2 * math.pi / numVerts) - irregularity
   upper = (2 * math.pi / numVerts) + irregularity
   sum = 0

   for i=0,numVerts-1 do
      local tmp =lower +  love.math.random()*(upper-lower)
      angleSteps[i] = tmp;
      sum = sum + tmp;
   end

   k = sum / (2 * math.pi)
   for i=0,numVerts-1 do
      angleSteps[i] = angleSteps[i] / k
   end

   points = {}
   angle = love.math.random()*(2.0*math.pi)
   for i=0,numVerts-1 do
      r_i = clip(gaussian(aveRadius, spikeyness)(), 0, 2*aveRadius)
      x = ctrX + r_i * math.cos(angle)
      y = ctrY + r_i * math.sin(angle)
      points[1 + i * 2 + 0] = math.floor(x)
      points[1 + i * 2 + 1] = math.floor(y)
      angle = angle + angleSteps[i]
   end
   return points
end

local bytemarkers = { {0x7FF,192}, {0xFFFF,224}, {0x1FFFFF,240} }
function utf8(decimal)
   if decimal<128 then return string.char(decimal) end
   local charbytes = {}
   for bytes,vals in ipairs(bytemarkers) do
      if decimal<=vals[1] then
         for b=bytes+1,2,-1 do
            local mod = decimal%64
            decimal = (decimal-mod)/64
            charbytes[b] = string.char(128+mod)
         end
         charbytes[1] = string.char(vals[2]+decimal)
         break
      end
   end
   return table.concat(charbytes)
end


function HSL(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h/256*6, s/255, l/255
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end
    return (r+m)*255, (g+m)*255, (b+m)*255,a
end

function transformPolygon(tx, ty, polygon)
	local result = {}
	local n = table.getn(polygon)
	for i=1,n,2 do
		result[i + 0] = polygon[i + 0] + tx
		result[i + 1] = polygon[i + 1] + ty
	end
	return result
end

function tablefind_id(tab, id)
    for index, value in pairs(tab) do
       if tostring(value.id) == id then
          return index
       end
    end
    return -1
end

function distance(x, y, x1, y1)
   local dx = x - x1
   local dy = y - y1
   local dist = math.sqrt(dx * dx + dy * dy)
   return dist
end

function center(x, x1)
   local dx = x - x1
   return x1 + dx/2
end

function signT(p1, p2, p3)
   return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
end

function pointInTriangle(p, t1, t2, t3)
   local b1, b2, b3
   b1 = signT(p, t1, t2) < 0.0
   b2 = signT(p, t2, t3) < 0.0
   b3 = signT(p, t3, t1) < 0.0

   return ((b1 == b2) and (b2 == b3))
end

function pointInPoly(point, triangles, offsetX, offsetY)
   local hit = false
   local index = 0
   if not triangles then return false,0 end
   for i=1, #triangles do
      local t = triangles[i]

      -- this ofset is added to do the parallax
      --print(t[1],t[2],t[3],t[4],t[5],t[6])
      local t1 = {x=t[1]+offsetX, y=t[2]+offsetY}
      local t2 = {x=t[3]+offsetX, y=t[4]+offsetY}
      local t3 = {x=t[5]+offsetX, y=t[6]+offsetY}




      --print(point.x, point.y, t[1]..","..t[2]..","..t[3]..","..t[4]..","..t[5]..","..t[6])
      hit = pointInTriangle(point, t1, t2, t3)
      if hit then
         index = i
         --print(t1.x, t2.x, t3.x)
         --print("triangle # ".. i .. " hit? ("..tostring(hit)..") total triangles"..#triangles )
         --print(point.x, point.y, t[1]..","..t[2]..","..t[3]..","..t[4]..","..t[5]..","..t[6])
      end

      if hit then break end
   end
   return hit, index
end


function pointInRect(x,y, rx, ry, rw, rh)
   if x < rx or y < ry then return false end
   if x > rx+rw or y > ry+rh then return false end
   return true
end

function pointInRect2(x,y, cx, cy, rw, rh)
   local w2 = math.abs(rw)/2
   local h2 = math.abs(rh)/2
   if x < cx-w2 or y < cy-h2 then return false end
   if x > cx+w2 or y > cy+h2 then return false end
   return true
end

function angle(x1,y1, x2, y2)
   local dx = x2 - x1
   local dy = y2 - y1
   return math.atan2(dx,dy)
end

function pointInCircle(x,y, cx, cy, radius)
   if distance(x,y,cx,cy) < radius then
      return true
   else
      return false
   end
end

function rotatePoint(x,y,cx,cy,theta)
   if not theta then return x,y end
   local px = math.cos(theta) * (x-cx) - math.sin(theta) * (y-cy) + cx
   local py = math.sin(theta) * (x-cx) + math.cos(theta) * (y-cy) + cy
   return px,py
end
function angleAtDistance(x,y,angle, distance)
   local px = math.cos( angle ) * distance
   local py = math.sin( angle ) * distance
   return px, py
end


function clamp(v, min, max)
   if v < min then return min end
   if v > max then return max end
   return v
end
function clip(value, min, max)
   if (min > max) then return value
   elseif (value < min) then return min
   elseif (value > max) then return max
   else return value end
end

function distancePointSegment(x,y, x1,y1, x2, y2)
   local A = x - x1
   local B = y - y1
   local C = x2 - x1
   local D = y2 - y1
   local dot    = A * C + B * D
   local len_sq = C * C + D * D
   local param = -1

   if (len_sq ~= 0) then
      param = dot / len_sq
   end

   local xx, yy
   if (param < 0) then
      xx = x1
      yy = y1
   elseif (param > 1) then
      xx = x2
      yy = y2
   else
      xx = x1 + param * C
      yy = y1 + param * D
   end

   local dx = x - xx
   local dy = y - yy
   return math.sqrt(dx * dx + dy*dy)
end

function moveAtAngle(x,y, angle, distance)
   local px = math.cos( angle ) * distance
   local py = math.sin( angle ) * distance
   return x + px, y + py
end

function calculateCoordsFromRotationsAndLengths(relative, data, x, y)
   local result = {}
   local rotation = 0
   local cx = data.coords and data.coords[1] or x
   local cy = data.coords and data.coords[2] or y

   table.insert(result, (cx))
   table.insert(result, (cy))

   if relative then
      for i=1,  #data.relative_rotations do
         cx, cy = moveAtAngle(cx, cy, data.relative_rotations[i] , data.lengths[i])
         table.insert(result, (cx))
         table.insert(result, (cy))
      end
   else
      for i=1,  #data.world_rotations do
         rotation = data.world_rotations[i] + rotation
         cx, cy = moveAtAngle(cx, cy, rotation , data.lengths[i])
         table.insert(result, (cx))
         table.insert(result, (cy))
      end
   end

   return result
end


return {
   HSL=HSL,
   utf8=utf8,
   generatePolygon=generatePolygon,
   transformPolygon=transformPolygon,
   tablefind_id = tablefind_id,
   distance=distance,
   angle=angle,
   center=center,
   pointInRect=pointInRect,
   pointInRect2=pointInRect2,
   pointInTriangle=pointInTriangle,
   pointInCircle=pointInCircle,
   pointInPoly=pointInPoly,
   rotatePoint=rotatePoint,
   angleAtDistance,
   clamp=clamp,
   distancePointSegment=distancePointSegment,
   moveAtAngle=moveAtAngle,
   calculateCoordsFromRotationsAndLengths=calculateCoordsFromRotationsAndLengths

}
