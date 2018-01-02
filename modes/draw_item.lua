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
end


function mode:update(dt)

   Hammer:pos(10,300)
   Hammer:ret()
   local delete = Hammer:labelbutton("delete", 100, 40)
   if delete.startpress then
      for i=#world.children,1,-1 do
         if world.children[i]==self.child then
            table.remove(world.children, i)
         end
      end
      Signal.emit("switch-state", "stage")

   end
   Hammer:ret()

   local escape = Hammer:labelbutton("ESCAPE", 100, 40)
   if escape.startpress then
      Signal.emit("switch-state", "stage")
      return
   end




   local result
   if self.firstTime == true then
      world.children[#world.children+1] = {type="polyline",pos={x=0,y=0,z=0}, data={coords={0,0,-10,-100 , 50, 50, 100,50,10,200},join="miter", half_width=10}}
      self.thicknesses = {10,10,10}

      self.firstTime = false
   end

   if #Hammer.pointers.pressed == 1 then

      if Hammer.pointers.pressed[1] and Hammer.pointers.moved[1] then
         if Hammer.pointers.pressed[1].id == Hammer.pointers.moved[1].id then
            if Hammer.pointers.moved[1].dx ~= 0 or Hammer.pointers.moved[1].dy ~= 0 then
               local wx,wy = camera:worldCoords(Hammer.pointers.moved[1].x, Hammer.pointers.moved[1].y)
               --if not (self.coords[#self.coords]==wy or  self.coords[#(self.coords)-1]==wx) then
                  --print(wx,wy)
                  --print(self.coords[#self.coords], wy ,self.coords[#(self.coords)-1],wx)
                  if #self.coords >= 4 then
                     local distance = (utils.distance(wx,wy,self.coords[#self.coords-1],self.coords[#self.coords]))
                     if distance > 50 then
                        table.insert(self.coords, wx)
                        table.insert(self.coords, wy)
                        local v = math.abs(Hammer.pointers.moved[1].dx) + math.abs(Hammer.pointers.moved[1].dy)
                        --table.insert(self.thicknesses, distance - 10)
                        table.insert(self.thicknesses, 10 + v*2)

                     end


                  else
                     table.insert(self.coords, wx)
                     table.insert(self.coords, wy)
                     table.insert(self.thicknesses, 10)

                  end


               --end

            end
         end
      end
   end
   --local wx,wy = camera:worldCoords(Hammer.pointers.moved[1].x, Hammer.pointers.moved[1].y)

   local c = self.coords
   if #self.coords < 4 then
      c = {0,0,1,0,1,1,0,1}
      self.thicknesses = {10,10,10,10,10}
   end

   world.children[#world.children].data.coords = c
   world.children[#world.children].data.thicknesses = self.thicknesses
   world.children[#world.children].dirty = true


end


return mode
