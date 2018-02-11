local utils = require "utils"

local mode = {}

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end


function mode:enter(from,data)
   self.needed_distance = {min=1, max=100, value=20}
   self.parent = data.parent
   self.coords = {}
   self.firstTime = true
end

function mode:update(dt)
   Hammer:reset(20,100)
   Hammer:ret()

   if Hammer:labelbutton("START", 100, 40).released then
      self.start = true
   end
   Hammer:ret()
   Hammer:label("nd1","req. dist."..math.floor(self.needed_distance.value), 200,40)
   Hammer:ret()
   Hammer:slider("distance", 200,40, self.needed_distance)
   Hammer:ret()

   if Hammer:labelbutton("ESCAPE", 100, 40).startpress then
      Signal.emit("switch-state", "stage")
      return
   end

   if not self.start then return end
   local result

   if #(Hammer.pointers.pressed) > 0 then
      if self.firstTime == true then
         self.parent.children[#self.parent.children+1] =  {
            type="polygon", pos={x=0, y=0, z=0},
            data={ steps=3,  points={{x=0,y=0}, {cx=100, cy=-100},{cx=200, cy=-100},{cx=300, cy=-100}, {x=200,y=0}, {x=200, y=200}, {x=0, y=250}} }
         }
         self.firstTime = false
      end
      if self.shapeHasEnded == true then
         self.shapeHasEnded = false
         self.parent.children[#self.parent.children+1] =  {
            type="polygon", pos={x=0, y=0, z=0},
            data={ steps=3,  points={{x=0,y=0}, {cx=100, cy=-100},{cx=200, cy=-100},{cx=300, cy=-100}, {x=200,y=0}, {x=200, y=200}, {x=0, y=250}} }
         }
         self.coords = {}
      end
   end

   if Hammer.pointers.pressed[1] and Hammer.pointers.moved[1] then
      if Hammer.pointers.pressed[1].id == Hammer.pointers.moved[1].id then
         local wx,wy = camera:worldCoords(Hammer.pointers.moved[1].x, Hammer.pointers.moved[1].y)

         if self.parent.inverse then
            wx,wy = self.parent.inverse(wx,wy)
         end

         if #self.coords >= 6 then
            local distance = (utils.distance(wx,wy,self.coords[#self.coords-1],self.coords[#self.coords]))
            if distance > self.needed_distance.value then
               table.insert(self.coords, wx)
               table.insert(self.coords, wy)
            end
         else
            if not(wx == self.coords[#self.coords-1] and wy ==self.coords[#self.coords]) then
               table.insert(self.coords, wx)
               table.insert(self.coords, wy)
            end
         end
      end
   end


   if #(Hammer.pointers.released) > 0 then
      if self.firstTime == false then
         self.shapeHasEnded = true
      end
   end

   if #self.coords >= 6 then
      self.parent.children[#self.parent.children].data.points = mapFlatCoordsToPoints(self.coords)
      self.parent.children[#self.parent.children].dirty = true
   end
end


function mapFlatCoordsToPoints(flat)
   local result = {}
   for i=1, #flat, 2 do
      table.insert(result, {x=flat[i+0],y=flat[i+1]})
   end
   return result
end


return mode
