local mode = {}

function mode:enter(from, data)
   self.child = data
   print("Hi entering edit polygon mode, lots of ui needs to be drawn here.")
end

function mode:pointerpressed(x,y,id)
   print("bye for now!")
    Signal.emit("switch-state", "stage")
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





return mode
