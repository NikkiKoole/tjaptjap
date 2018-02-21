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

local duration_value = {min=0, max=10.0, value=1.0}

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
   self.draggedItems = {}
   self.selectedItems = {}
   self.time = 0
   self.isRecording = false
   self.isReplaying = false
   clearAllAnimations()

   self.frameDictionary = {}
   self.tweenOptionIndex = 1
   self.lineStyles = {"coords", "world", "relative"}
   self.lineStyleIndex = 1
end



function getNestedRotation(child, index)
   local result = 0
   for i=index,1,-1 do
      if child.data.world_rotations[i] then
         result = result + child.data.world_rotations[i]
      end
   end
   return result
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

function table_copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table_copy(k, s)] = table_copy(v, s) end
  return res
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

   Hammer:pos(10,200)



   local tween_options = {"linear","quadin","quadout","quadinout","cubicin","cubicout","cubicinout","quartin","quartout","quartinout","quintin","quintout","quintinout","expoin","expoout","expoinout","sinein","sineout","sineinout","circin","circout","circinout","backin","backout","backinout","elasticin","elasticout","elasticinout"}

   local tween_button = Hammer:labelbutton(tween_options[self.tweenOptionIndex], 130,40)
   if tween_button.released then
      self.tweenOptionIndex = self.tweenOptionIndex + 1
      if self.tweenOptionIndex > #tween_options then
         self.tweenOptionIndex = 1
      end
   end

   local tween_duration = Hammer:slider("tweenduration", 150,40, duration_value)
   Hammer:ret()


   if #self.selectedItems == 1 then
      --if self.selectedItems[1].item.type == "polygon" then

      local save_data_points_for_tweening = Hammer:labelbutton("save frame", 130, 40)
      if save_data_points_for_tweening.released then
         if #self.selectedItems == 1 then

            for i=1, #self.selectedItems do

               local it = self.selectedItems[i].item

               if it.type == "polygon" then
                  table.insert(self.frameDictionary, table_copy(it.data.points))
               elseif it.type == "smartline" then
                  table.insert(self.frameDictionary, table_copy(it.data))

               else
                  print("unknwn type for saving")
               end


            end
         else
            print("not yet handling multiple in selection, only the one.")
         end
      end



   end



   Hammer:ret()


   if #self.selectedItems == 1 then
      if self.selectedItems[1].item.type == "smartline" then
         local linetype = Hammer:labelbutton(self.lineStyles[self.lineStyleIndex], 130,40)
         if linetype.released then
            self.lineStyleIndex= self.lineStyleIndex + 1
            if self.lineStyleIndex > #self.lineStyles then
               self.lineStyleIndex = 1
            end
         end


         Hammer:ret()

      end


      for i=1, #self.frameDictionary do
         local frameButton = Hammer:labelbutton(self.selectedItems[1].item.id.."  #"..i, 130,40)
         if Hammer.x + 200 >= love.graphics.getWidth() then
            Hammer:ret()
         end

         if frameButton.released then
            local it = self.selectedItems[1].item

            if self.selectedItems[1].item.tween then self.selectedItems[1].item.tween:stop() end

            if it.type == "polygon" then
               for j=1, #it.data.points do
                  local c =  self.selectedItems[1].item.data.points[j]
                  local f = self.frameDictionary[i][j]
                  if (f.x and f.y) then
                     self.selectedItems[1].item.tween = flux.to(c, duration_value.value or 1, {x=f.x, y=f.y}):ease(tween_options[self.tweenOptionIndex])
                        :onupdate(
                           function()
                              self.selectedItems[1].item.data.points[j] = c
                              self.selectedItems[1].item.dirty = true
                           end
                                 )
                  elseif (f.cx and f.cy) then
                     self.selectedItems[1].item.tween =flux.to(c, duration_value.value or 1, {cx=f.cx, cy=f.cy}):ease(tween_options[self.tweenOptionIndex])
                        :onupdate(
                           function()
                              self.selectedItems[1].item.data.points[j] = c
                              self.selectedItems[1].item.dirty = true
                           end
                                 )
                  end


               end
            elseif it.type == "smartline" then
               local style = self.lineStyles[self.lineStyleIndex]
               if style == "coords" then
                  local f = self.frameDictionary[i].coords
                  local c =  self.selectedItems[1].item.data.coords

                  self.selectedItems[1].item.tween = flux.to(c, duration_value.value or 1, f):ease(tween_options[self.tweenOptionIndex])
                  :onupdate(
                     function()
                        self.selectedItems[1].item.data.coords = c
                        self.selectedItems[1].item.dirty = true
                     end
                           )
               elseif style == "world" then
                  local f = self.frameDictionary[i].world_rotations
                  local c =  self.selectedItems[1].item.data.world_rotations

                  self.selectedItems[1].item.tween = flux.to(c, duration_value.value or 1, f):ease(tween_options[self.tweenOptionIndex])
                  :onupdate(
                     function()
                        self.selectedItems[1].item.data.world_rotations = c
                        local new_coords = utils.calculateCoordsFromRotationsAndLengths(false, self.selectedItems[1].item.data)
                        self.selectedItems[1].item.data.coords = new_coords
                        self.selectedItems[1].item.dirty = true
                     end
                           )

               elseif style == "relative" then
                  local f = self.frameDictionary[i].relative_rotations
                  local c =  self.selectedItems[1].item.data.relative_rotations

                  self.selectedItems[1].item.tween = flux.to(c, duration_value.value or 1, f):ease(tween_options[self.tweenOptionIndex])
                  :onupdate(
                     function()
                        self.selectedItems[1].item.data.relative_rotations = c
                        local new_coords = utils.calculateCoordsFromRotationsAndLengths(true, self.selectedItems[1].item.data)
                        self.selectedItems[1].item.data.coords = new_coords
                        self.selectedItems[1].item.dirty = true
                     end
                           )

               end


            else
            end



         end
      end

   end

   Hammer:ret()


   -- for i=#self.selectedItems, 1,-1 do
   --    local it = self.selectedItems[i]
   --    local b = Hammer:labelbutton(tostring(it.item.id), 130,40)
   --    if b.released then
   --       local foundIndex = getIndexOfItem(it.item, self.selectedItems)
   --       if foundIndex > 0 then
   --          table.remove(self.selectedItems, foundIndex)
   --       end
   --    end
   -- end
   for j=1, #self.selectedItems do
      local child = self.selectedItems[j].item

      -- if child is poly
      if child.type=="polygon" then
         for i=1, #child.data.points do
            local point = child.data.points[i]
            local cx2, cy2 = camera:cameraCoords(child.world_trans((point.x or point.cx), (point.y or point.cy)))
            local color

            if point.x and point.y then
               color={0,100,100}
            else
               color={200,100,100}
            end

            local button = Hammer:rectangle( "poly-handle"..i.."__"..j, 30, 30, {x=cx2-15, y=cy2-15, color=color})

            if button.dragging then
               local p = getWithID(Hammer.pointers.moved, button.pointerID)
               local moved = Hammer.pointers.moved[p]
               if moved then

                  local wx,wy = camera:worldCoords(moved.x-button.dx, moved.y-button.dy)
                  wx,wy = child.inverse(wx,wy)

                  if point.x and point.y then
                     child.data.points[i].x = wx
                     child.data.points[i].y = wy
                  elseif point.cx and point.cy then
                     child.data.points[i].cx = wx
                     child.data.points[i].cy = wy
                  end
                  child.dirty = true
               end
            end
         end
      elseif child.type == "smartline" then
         local recipe = self.lineStyles[self.lineStyleIndex]

         for i=1, #child.data.coords, 2 do
            local x,y = child.data.coords[i], child.data.coords[i+1]
            local cx2, cy2 = camera:cameraCoords(child.world_trans(x,y))
            local color = {200,200,200}
            local button = Hammer:rectangle( "smartline-handle"..i, 30, 30,
                                             {x=cx2-15, y=cy2-15, color=color})


            ------ DUPLICATION FROM edit_smartline
            if button.dragging then
               local p = getWithID(Hammer.pointers.moved, button.pointerID)
               local moved = Hammer.pointers.moved[p]
               if moved then
                  local wx,wy = camera:worldCoords(moved.x-button.dx, moved.y-button.dy)
                  wx,wy = child.inverse(wx,wy)

                  if recipe == 'coords' then
                     child.data.coords[i  ] = wx
                     child.data.coords[i+1] = wy
                     local props = calculateAllPropsFromCoords(child.data.coords)
                     child.data.relative_rotations = props.relative_rotations
                     child.data.world_rotations = props.world_rotations
                     child.data.lengths = props.lengths

                  elseif recipe == 'relative' then
                     if i > 1 then
                        local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                        local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)
                        child.data.relative_rotations[-1 + (i+1)/2] =  angleToRelative(ap)
                        local p2 = calculateAllPropsFromCoords(child.data.coords)
                        child.data.lengths = p2.lengths
                        local new_coords = utils.calculateCoordsFromRotationsAndLengths(true, child.data)
                        child.data.coords = new_coords
                        local props = calculateAllPropsFromCoords(child.data.coords)
                        child.data.relative_rotations = props.relative_rotations
                        child.data.world_rotations = props.world_rotations
                     end

                  elseif recipe == "world" then
                     if i > 1 then
                        local ap = utils.angle( wx, wy, child.data.coords[i-2], child.data.coords[i+1-2])
                        local dp = utils.distance(child.data.coords[i-2], child.data.coords[i+1-2], wx, wy)
                        local startAngle = getNestedRotation(child, ((i+1)/2)-2)
                        print(inspect(child.data.world_rotations))
                        child.data.world_rotations[-1+(i+1)/2] = angleToWorld(ap) - startAngle
                        local p2 = calculateAllPropsFromCoords(child.data.coords)
                        child.data.lengths = p2.lengths
                        local new_coords = utils.calculateCoordsFromRotationsAndLengths(false, child.data)
                        child.data.coords = new_coords
                        local props = calculateAllPropsFromCoords(child.data.coords)
                        child.data.relative_rotations = props.relative_rotations
                        child.data.world_rotations = props.world_rotations
                     end
                  end

                  child.dirty = true
               end
            end

            ---------------------------------------------- EDN DUPLICATION
         end

      else

      end



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
   if #self.selectedItems > 0 then return end


   for i,it in pairs(self.draggedItems) do
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
         table.insert(self.draggedItems, {id=id, item=o})
      end
   end
end

function getIndexOfItem(child, list)
   for i=1, #list do
      if list[i].item == child then return i end
   end
   return 0
end


function mode:pointerreleased(x,y,id)
   for i,it in pairs(self.draggedItems) do
      if (it.id == id) then
         table.remove(self.draggedItems, i)
      end
   end
   --
   for i,o in pairs(world.children) do
      if testHit(x,y,o) then
         local foundIndex = getIndexOfItem(o, self.selectedItems)
         if foundIndex == 0 then
            table.insert(self.selectedItems, {id=id, item=o})
         else
            --table.remove(self.selectedItems, foundIndex)
         end
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
