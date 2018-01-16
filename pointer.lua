
local pointers = {
   pressed = {},
   moved = {},
   released = {},
}

function removeItemWithIDFromList(id, list)
   if (list) then
      for i=#list,1 ,-1 do
         if list[i].id == id then
            table.remove(list, i)
         end
      end
   end
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


function pointerReleased(p)
   table.insert(pointers.released, p)
   removeItemWithIDFromList( p.id, pointers.pressed)
   removeItemWithIDFromList(p.id, pointers.moved)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
   pointerReleased({id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})
end
function love.mousereleased(x, y, button, isTouch)
   if (not istouch) then
      pointerReleased({id="mouse", x=x, y=y})
   end

end


function pointerMoved(p)
   --print("pointer moved: ",p.id)
   local i = listGetPointerIndex(pointers.moved, p.id)
   if i == -1 then
      table.insert(pointers.moved, p)
   else
      pointers.moved[i].x = p.x
      pointers.moved[i].y = p.y
      pointers.moved[i].dx = p.dx
      pointers.moved[i].dy = p.dy
      pointers.moved[i].pressure = p.pressure
   end
end


function love.mousemoved(x, y, dx, dy,  istouch)
   if (not istouch) then
      pointerMoved({id="mouse", x=x, y=y, dx=dx, dy=dy})
   end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
   pointerMoved({id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})
end

function pointerPressed(pointer)
   table.insert(pointers.pressed, pointer)
end
function love.mousepressed(x, y, button, istouch )
   if (not istouch) then
      pointerPressed({id="mouse", x=x, y=y})
   end
end
function love.touchpressed(id, x, y, dx, dy, pressure)
   pointerPressed({id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})
end





--------------------------------
return pointers
