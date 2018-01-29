local utils = require "utils"

local mode = {}

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end


function mode:enter(from,data)
   self.coords = {}
   self.thicknesses = {}
   self.firstTime = true
   self.next_thick_value = {min=1, max=100, value=10}
   self.needed_distance = {min=1, max=100, value=20}

   self.use_thickness_func = 0
   self.start = false
end


function mode:update(dt)

   Hammer:reset(10,300)
   Hammer:ret()

   if Hammer:labelbutton("START", 100, 40).released then
      self.start = true
   end
   Hammer:ret()
   Hammer:label("nd1","req. dist."..math.floor(self.needed_distance.value), 200,40)
   Hammer:ret()
   Hammer:slider("distance", 200,40, self.needed_distance)
   Hammer:ret()
   local thick_label = "use thickness slider"
   if self.use_thickness_func>0 then
      thick_label = "use thickness func"..self.use_thickness_func
   end
   if Hammer:labelbutton(thick_label, 250,40).released then

      self.use_thickness_func = self.use_thickness_func+1
      if self.use_thickness_func > 2 then
         self.use_thickness_func = 0
      end

   end
   Hammer:ret()

   if self.use_thickness_func==0 then
      Hammer:slider("next_thickness", 200,40, self.next_thick_value)
   end
   Hammer:ret()



   if Hammer:labelbutton("ESCAPE", 100, 40).startpress then
      Signal.emit("switch-state", "stage")
      return
   end

   if not self.start then return end
   local result


   if #(Hammer.pointers.pressed) > 0 then
      if self.firstTime == true then
         world.children[#world.children+1] = {type="polyline", world_pos={x=0,y=0,z=0}, pos={x=0,y=0,z=0}, data={coords={0,0,-10,-100 , 50, 50, 100,50,10,200},join="miter", half_width=10}}
         self.thicknesses = {}
         self.firstTime = false
      end

      if Hammer.pointers.pressed[1] and Hammer.pointers.moved[1] then
         if Hammer.pointers.pressed[1].id == Hammer.pointers.moved[1].id then
               local wx,wy = camera:worldCoords(Hammer.pointers.moved[1].x, Hammer.pointers.moved[1].y)
               if #self.coords >= 4 then
                  local distance = (utils.distance(wx,wy,self.coords[#self.coords-1],self.coords[#self.coords]))
                  if distance > self.needed_distance.value then
                     table.insert(self.coords, wx)
                     table.insert(self.coords, wy)
                     local v = math.abs(Hammer.pointers.moved[1].dx) + math.abs(Hammer.pointers.moved[1].dy)

                     if self.use_thickness_func == 1 then
                        table.insert(self.thicknesses, 50 - v*2)
                     elseif self.use_thickness_func == 2 then
                        table.insert(self.thicknesses, 10 + v*2)
                     else
                        table.insert(self.thicknesses,self.next_thick_value.value)
                     end
                  end
               else
                  if not(wx == self.coords[#self.coords-1] and wy ==self.coords[#self.coords]) then
                     table.insert(self.coords, wx)
                     table.insert(self.coords, wy)
                     local v = math.abs(Hammer.pointers.moved[1].dx) + math.abs(Hammer.pointers.moved[1].dy)

                     if self.use_thickness_func then
                        table.insert(self.thicknesses, 10 + v*2)
                     else
                        table.insert(self.thicknesses,self.next_thick_value.value)
                     end
                  end


               end
         end
      end
   end

   if #self.coords >= 4 then
      world.children[#world.children].data.coords = self.coords
      world.children[#world.children].data.thicknesses = self.thicknesses
      world.children[#world.children].dirty = true
   end

end


return mode
