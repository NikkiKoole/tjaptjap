--[[

   This mode lets you drag items on stage and change its properties (rotation, scale, shape etc)
   You can also make a recording of such a session

   It does mean however that I'll need a lot of UI for all different types of items,
   Most of this ui and logic currently is buried in specific modes

   I suppose some generalist UI could come in handy too,
   like some moveable widgets to rotate or some slider to change props.

   You should be able to select multipe items and change both their properties at the same time

--]]

local mode = {}




function saveFrame()
   for i,child in pairs(world.children) do
      child.animationStartFrame = {x=child.pos.x, y=child.pos.y}
   end
end
function setBackSavedFrame()
   for i,child in pairs(world.children) do
      child.pos.x = child.animationStartFrame.x
      child.pos.y = child.animationStartFrame.y
   end
end
function clearAllAnimations()
   for i,child in pairs(world.children) do
      child.animation = {}
   end

end



function compare(a,b)
  return a.time < b.time
end

function replayAnimation(time)
   for i,o in pairs(world.children) do
      if o.animation then
         table.sort(o.animation, compare)
         -- reset child
         o.pos.x = o.animationStartFrame and o.animationStartFrame.x or 0
         o.pos.y = o.animationStartFrame and o.animationStartFrame.y or 0
         o.dirty=true
         for i=1, #o.animation-1 do
            local value = o.animation[i]
            local nex = o.animation[i+1]
            if nex.time > time and value.time <= time then
               if value.type == "pos" then
                  --print(inspect(value))
                  o.pos = {x=value.x, y=value.y, z=0}
                  o.dirty = true
               end
            end
         end
      end
   end
end



function mode:enter(from, data)

   self.selectedItems = {}
   self.time = 0
   self.isRecording = false
   self.isReplaying = false
   clearAllAnimations()
end


function secondsToClock(seconds)
  local seconds = tonumber(seconds)
  if seconds <= 0 then
     return (math.floor(math.abs(seconds))+1)
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins  = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs  = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    ms    = string.format("%03.f", math.floor((seconds - math.floor(seconds)) * 1000));
    return hours..":"..mins..":"..secs..":"..ms
  end
end

function mode:update(dt)
   self.dirty_types = {}
   Hammer:reset(10, 100)



   local stage_mode = Hammer:labelbutton("stage mode", 130,40)
   if stage_mode.released then
      self.touches = {}
      Signal.emit("switch-state", "stage", {pointerID=id})
   end

   Hammer:pos(10,10)

   local timeStr
   if self.isRecording then timeStr = secondsToClock(self.time)  else  timeStr = "---"  end
   Hammer:labelbutton(timeStr, 130,40)

   local recButtonStr
   if self.isRecording then recButtonStr = "STOP" else recButtonStr = "REC"  end


   if Hammer:labelbutton(recButtonStr,130,40 ).released then
      if self.isRecording then
         self.isRecording = false
      else
         self.isRecording = true
         self.time = -1
         saveFrame()
      end
   end


   local replayStr
   if self.isReplaying then replayStr = secondsToClock(self.time) else replayStr = "Replay" end
   if Hammer:labelbutton(replayStr, 130, 40).released then
      self.duration = self.time
      self.time = 0
      self.isReplaying = true
      if self.duration == 0 then
         self.isReplaying = false
      end
   end

   if self.isReplaying then
      if self.time <= self.duration then
         replayAnimation(self.time)
      else
         self.isReplaying = false
         --setBackSavedFrame()

      end
   end

   Hammer:ret()
   local inspectt = Hammer:labelbutton("inspect", 130,40)
   if inspectt.released then
      for i, child in pairs(world.children) do
         if child.animation then
            for j=1, #child.animation do
               print((child.animation[j].time))
            end
         end
      end
   end



   if self.isRecording or self.isReplaying then
      self.time = self.time + dt
   end
end


function testHit(x,y, obj)
   local result = false
   local wx, wy = camera:worldCoords(x,y)

   if obj.triangles then
      if pointInPoly({x=wx,y=wy}, obj.triangles) then
         result = true
      end
   end
   if obj.children then
      for i,o in pairs(obj.children) do
         if testHit(x,y, o) then
            result = true
         end
      end
   end

   return result
end

function mode:pointermoved(id, x, y, dx, dy)
   -- find item
   local item
   for i,it in pairs(self.selectedItems) do
      if (it.id == id) then
         item = it.item
         break
      end
   end

   if item then
      item.pos.x = item.pos.x + dx/camera.scale
      item.pos.y = item.pos.y + dy/camera.scale
      item.dirty = true
      if self.isRecording and self.time >= 0 then
         item.dirty_types = {type="pos", time=self.time, x=item.pos.x, y=item.pos.y}
      end
   end

end

function mode:mousemoved(x, y, dx, dy, istouch)
   if not istouch then
      self:pointermoved("mouse",x,y,dx,dy)
   end
end

function mode:touchmoved( id, x, y, dx, dy, pressure )
      self:pointermoved(id,x,y,dx,dy)
end

function mode:pointerpressed(x, y, id)
   for i,o in pairs(world.children) do
      if testHit(x,y,o) then
         table.insert(self.selectedItems, {id=id, item=o})
         print("hit! "..o.type.." id:"..tostring(id))
      end
   end
end

function mode:pointerreleased(x,y,id)
   for i,it in pairs(self.selectedItems) do
      if (it.id == id) then
         table.remove(self.selectedItems, i)
      end
   end
end

function mode:mousepressed( x, y, button, istouch )
   if (not istouch) then
      self:pointerpressed(x, y, "mouse")
   end
end

function mode:touchpressed( id, x, y, dx, dy, pressure )
   self:pointerpressed(x, y, id)
end

function mode:mousereleased(x,y,button, istouch)
   if (not istouch) then
      self:pointerreleased(x,y,"mouse")
   end
end

function mode:touchreleased( id, x, y, dx, dy, pressure )
   self:pointerreleased(x,y,id)
end





return mode
