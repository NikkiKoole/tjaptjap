local mode = {}

function mode:update()
   Hammer:reset(0,0)
   if Hammer:labelbutton('stage', 70,40).released then
      Signal.emit("switch-state", "stage")
   end
end


return mode
