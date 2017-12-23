local hammer = {}

function distance(x, y, x1, y1)
   local dx = x - x1
   local dy = y - y1
   local dist = math.sqrt(dx * dx + dy * dy)
   return dist
end



function pointInRect(x,y, rx, ry, rw, rh)
   if x < rx or y < ry then return false end
   if x > rx+rw or y > ry+rh then return false end
   return true
end
function listGetPointerIndex(list, id)
   if (list) then
      for i=#list,1 ,-1 do
         if list[i].id == id then
            return  i
         end
      end
   end
   return -1
end



function hammer:panel()
end

function hammer:reset(x,y)
   self.drawables = {}
   self.x = x
   self.originX = x
   self.y = y
   self.originY = y

   self.margin = 10
   self.rowHeight = 40

end
function hammer:pos(x,y)
   self.x = x
   self.originX = x
   self.y = y
   self.originY = y

end
function hammer:ret()
   self.x = self.originX
   self.y = self.y + self.rowHeight + self.margin
end

function hammer:circle(id, radius, opt_pos)
   local result =  {type="circle",id=id,
                    x=opt_pos.x or self.x,
                    y=opt_pos.y or self.y,
                    r=radius}

   table.insert(self.drawables, result)
   --self.x = self.x + radius*2 + self.margin
   return result

end



function hammer:label(id, text, width, height, opt_pos)
   local result =  {type="label",text=text,id=id,
                    x=opt_pos and opt_pos.x or self.x,
                    y=opt_pos and opt_pos.y or self.y,
                    w=width,h=height}
   table.insert(self.drawables, result)
   self.x = self.x + width + self.margin
   return result
end


function hammer:slider(id, width, height, props)
   local result =  {type="slider",thumbX=0, thumbY=0, id=id,x=self.x, y=self.y, w=width,h=height}


   if (self.history) then
      local  hi = listGetPointerIndex(self.history, id)
      if hi > -1 then
         if self.history[hi].startdrag or self.history[hi].dragging then
            result.dragging = true
            result.pointerID = self.history[hi].pointerID
            result.dx = self.history[hi].dx
            result.dy = self.history[hi].dy
         end
      end
   end




   local range = (props.max - props.min)
   local space = math.max(width, height) - math.min(width, height)

   if width > height then
      result.thumbX = ((props.value - props.min)/range)*space
   else
      result.thumbY = ((props.value - props.min)/range)*space
   end


   for i=1, #self.pointers.pressed do
      local pressed = self.pointers.pressed[i]

      if (pointInRect(pressed.x,
                      pressed.y,
                      self.x + result.thumbX,
                      self.y + result.thumbY,
                      math.min(width, height),
                      math.min(width, height))) then
         result.pressed = true
         result.startdrag = true
         result.pointerID = pressed.id
         result.dx = pressed.x - (self.x + result.thumbX)
         result.dy = pressed.y - (self.y + result.thumbY)

      end
   end



   for i=1, #self.pointers.moved do
      if (pointInRect(self.pointers.moved[i].x,
                      self.pointers.moved[i].y,
                      self.x + result.thumbX,
                      self.y + result.thumbY,
                      math.min(width, height),
                      math.min(width, height))) then
         result.over = true
         if result.startdrag then
            result.startdrag = false
            result.dragging = true
         end

      end
      if result.dragging then
         if result.pointerID == self.pointers.moved[i].id then
            local x
            if width > height then
               x = (self.pointers.moved[i].x - self.x) - result.dx
            else
               x = (self.pointers.moved[i].y - self.y) - result.dy
            end

            local v = props.min + (x / space) *range
            v = math.min(props.max, v)
            v = math.max(props.min, v)
            props.value = v
         end
      end

   end

   for i=1, #self.pointers.released do
      if self.pointers.released[i].id == result.pointerID then
         result.dragging = false
         result.enddrag = true
         result.released = true
         result.dx = false
         result.dy = false
      end
   end


   table.insert(self.drawables, result)
   self.x = self.x + width + self.margin
   return result
end




function hammer:rectangle(id, width, height, opt_pos)
   local result =  {type="rect",id=id,
                    dx=0,dy=0,
                    x=(opt_pos and opt_pos.x or self.x),
                    y=(opt_pos and opt_pos.y or self.y),
                    w=width,h=height}

   if opt_pos and opt_pos.color then
      result.color = opt_pos.color
   end


   if (self.history) then
      local  hi = listGetPointerIndex(self.history, id)
      if hi > -1 then

         if self.history[hi].dx and self.history[hi].dy then
            result.dx = self.history[hi].dx
            result.dy = self.history[hi].dy
         end


         if self.history[hi].startdrag or self.history[hi].dragging then
            result.dragging = true
            result.pointerID = self.history[hi].pointerID
         end
      end
   end

   if #self.pointers.pressed > 0 then
      --print("pressed ", #self.pointers.pressed)
   end




   for i=1, #self.pointers.pressed do
      local pressed = self.pointers.pressed[i]

      if (pointInRect(pressed.x,
                      pressed.y,
                      result.x,
                      result.y,
                      width, height)) then

         result.pressed = true
         result.dragging = true
         --result.startdrag = true
         result.pointerID = pressed.id
         if result.dx == 0 and result.dy == 0 then
         result.dx = pressed.x - (result.x + width/2)
         result.dy = pressed.y - (result.y + height/2)
         end
      else

      end

   end
   for i=1, #self.pointers.moved do

      if (pointInRect(self.pointers.moved[i].x,
                      self.pointers.moved[i].y,
                      result.x,
                      result.y,
                      width, height)) then
         result.over = true


         -- if result.startdrag then
         --    result.startdrag = false
         --    result.dragging = true
         -- end
      end
   end


   for i=1, #self.pointers.released do
      if self.pointers.released[i].id == result.pointerID then


         result.dragging = false
         result.startdrag = false
         result.enddrag = true
         result.released = true
         result.dx = 0
         result.dy = 0
      end
   end

   table.insert(self.drawables, result)
   self.x = self.x + width + self.margin

   --self.y = self.y + height
   return result
end

function hammer:button(label)

end

function hammer:draw()
   love.graphics.setColor(255,255,255)
   self.history = {}
   for i=1, #(self.drawables) do
      local it = self.drawables[i]
      love.graphics.setColor(255,255,255)
      if (it.color) then
         love.graphics.setColor(it.color[1],it.color[2],it.color[3], 100)
      end

      if (it.over) then
         love.graphics.setColor(255,0,255)
      end


      if (it.pressed) then
         love.graphics.setColor(255,0,0)
      end

       if (it.dragging) then
         love.graphics.setColor(55,222,255)
      end

       if it.type == "circle" then
         love.graphics.circle("fill", it.x, it.y, it.r)
      end

      if it.type == "rect" then
         love.graphics.rectangle("fill", it.x, it.y, it.w, it.h)
      end
      if it.type == "slider" then
         love.graphics.rectangle("fill", it.x, it.y, it.w, it.h)

         love.graphics.setColor(255,0,0, 150)
         love.graphics.rectangle("fill", it.x + it.thumbX, it.y + it.thumbY, math.min(it.w, it.h), math.min(it.w, it.h))

      end
      if it.type == "label" then
         love.graphics.setColor(55,55,55)
         love.graphics.rectangle("fill", it.x, it.y, it.w, it.h)
         local w = (love.graphics.getFont():getWidth(it.text))
         local h = (love.graphics.getFont():getHeight())

         local yOff = (it.h - h)/2 -- vertical center
         --local yOff = (it.h - h) -- vertical bottom
         local xOff = (it.w - w)/2

         love.graphics.setColor(155,155,155, 100)
         --love.graphics.rectangle("fill", it.x + xOff, it.y + yOff, w, h)


         love.graphics.setColor(70,50,50)
         love.graphics.print(it.text, it.x + xOff+1, it.y + yOff + 1)

         love.graphics.setColor(200,200,150)
         love.graphics.print(it.text, it.x + xOff, it.y + yOff)
      end


      table.insert(self.history, {id=it.id, color=it.color, dx=it.dx, dy=it.dy, dragging=it.dragging, startdrag=it.startdrag, pointerID=it.pointerID})
   end

   self.pointers.released = {}
end


return hammer
