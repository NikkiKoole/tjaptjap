--[[

]]--

--local suit = require 'vendor.suit'
Signal = require 'vendor.signal'
Gamestate = require "vendor.gamestate"
Camera = require "vendor.camera"
local inspect = require "vendor.inspect"

StageMode = require "modes.stage"
DragMode = require "modes.drag_item"
DrawMode = require "modes.draw_item"

ItemMode = require "modes.edit_item"
PolygonMode = require "modes.edit_polygon"
PolyLineMode = require "modes.edit_polyline"
Mesh3dMode = require "modes.edit_mesh3d"

RopeMode = require "modes.edit_rope"
Hammer = require "hammer"

local utils = require "utils"
local shapes = require "shapes"
poly = require 'poly'

-- storage for text input
local input = {text = ""}
local slider = {value = 1, min = 0, max = 2}
local checkbox = {checked = true, text="stuff"}

--------------------------------

local pointers = {
   pressed = {},
   moved = {},
   released = {},
}

function removePointer(list, id)
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
   removePointer(pointers.pressed, p.id)
   removePointer(pointers.moved, p.id)
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

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

function love.load()
   if arg[#arg] == "-debug" then require("mobdebug").start() end
   love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, {resizable=true, vsync=true, fullscreen=false})

   --icon_font = love.graphics.newFont("resources/icons.ttf", 30)
   helvetica = love.graphics.newFont("resources/helvetica_bold.ttf", 18)
   world = {
      children={
         {
            type="mesh3d",
            pos={x=0,y=0,z=0},
            data={width=3, height=10, cellwidth=50, cellheight=50}
         },
         {
            type="rope",
            pos={x=100,y=100,z=0},
            data={
               join="miter",
               relative_rotation = true,
               rotations={0, 0, 0, 0, 0, 0,0,0,0},
               lengths={120,120,100,100,100,100,100,100 },
               thicknesses={20,50,60,70,70,70,70,60,20},
            }
         },
         -- {type="rope",
         --  pos={x=-100,y=100,z=0},
         --  data={
         --     join="miter",
         --     relative_rotation = false,
         --     rotations={-math.pi/2,-0.8,-0.8,0.8},
         --     lengths={120,120,100,50},
         --     thicknesses={40,40,30,20,20},
         --  }
         -- },


         -- {type="polyline", pos={x=0,y=0,z=0}, data={coords={0,0,-10,-100 , 50, 50, 100,50,10,200}, join="miter", half_width=50, thicknesses={10,20,30,40,50}  }},
         -- {type="rect", rotation=0, pos={x=300, y=100, z=0}, data={w=200, h=200, radius=50, steps=8}},
         -- {type="circle", pos={x=500, y=100, z=0}, data={radius=200, steps=2}},
         -- {type="star", rotation=0.1, pos={x=0, y=300, z=0}, data={sides=8, r1=100, r2=200, a1=0, a2=0}},
         --{type="polygon", pos={x=0, y=0, z=0}, data={ steps=3,  points={{x=0,y=0}, {cx=100, cy=-100},{cx=200, cy=-100},{cx=300, cy=-100}, {x=200,y=0}, {x=200, y=200}, {x=0, y=250}} }}
      },
   }



   bounds = {
       tl={x = -1000,  y = -1000},
       br={x = 1000, y = 1000}
   }

    for i=1, #world.children do
      local c = world.children[i]
      local shape = shapes.makeShape(c)
      if c.rotation then
         shape = shapes.rotateShape(c.pos.x, c.pos.y, shape, c.rotation)
      end

      c.triangles = poly.triangulate(c.type, shape)
   end

   camera = Camera(0, 0)
   Gamestate.registerEvents()
   Gamestate.switch(StageMode)

   Signal.register(
      'switch-state',
      function(state, data)
         local State = nil
         if state == "stage" then
            State = StageMode
         elseif state == "drag-item" then
            State = DragMode
         elseif state == "draw-item" then
            State = DrawMode
         elseif state == "edit-item" then
            State = ItemMode
         elseif state == "edit-polygon" then
            State = PolygonMode
         elseif state == "edit-polyline" then
            State = PolyLineMode
         elseif state == "edit-mesh3d" then
            State = Mesh3dMode
         elseif state == "edit-rope" then
            State = RopeMode
         end
         Gamestate.switch(State, data)
      end
   )
   love.graphics.setFont(helvetica)

   pointers = {moved={}, released={}, pressed={}}

end

function love.keypressed(key)
   if key == "s" then
      --serializedString = bitser.dumps(world)
      --love.filesystem.write("filename.bin", serializedString)
      local serialized = inspect(world)
      love.filesystem.write("filename.txt", serialized)
   end
   if key == "o" then
      --love.system.openURL("file://"..love.filesystem.getSaveDirectory())

      local data = love.filesystem.newFileData("filename.txt")
      world = loadstring("return "..data:getString())()
   end
   	--suit.keypressed(key)

end

function love.filedropped(file)
   local data = love.filesystem.newFileData(file)
   world = loadstring("return "..data:getString())()
   --world = bitser.loadData(data:getPointer(), data:getSize())
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


function love.update(dt)
   if love.keyboard.isDown("escape") then love.event.quit() end
   for i=1, #world.children do
      if (world.children[i].dirty) then
         world.children[i].dirty = false
         local c = world.children[i]
         local shape = shapes.makeShape(c)
         if c.rotation then
            shape = shapes.rotateShape(c.pos.x, c.pos.y, shape, c.rotation)
         end
            c.triangles = poly.triangulate(c.type, shape)
      end
   end
   Hammer:reset(200,30)
   Hammer.pointers = pointers--{pressed={}, moved={}, released={}}
   local b = Hammer:rectangle("r3", 40,40)

end

function love.draw()
   --love.graphics.print("pointers  pressed: "..(#pointers.pressed), 0, 60)
   --love.graphics.print("pointers released: "..(#pointers.released), 0, 90)

   camera:attach()
   local triangle_count = 0
   for i=1, #world.children do
      if world.children[i].triangles  then
         for j=1, #world.children[i].triangles do
            love.graphics.setColor(math.random()*200 + 100, 155+ math.random()*0 + 20,55, 155)
            love.graphics.polygon("fill", world.children[i].triangles[j])
            triangle_count = triangle_count + 1
         end
      else
         --print("child at index "..i.." has no triangles.")
      end

   end


   camera:detach()

   love.graphics.setColor(255,255,255)
   love.graphics.print("camera " .. math.floor(camera.x) .. ", " .. math.floor(camera.y) .. "," .. tonumber(string.format("%.3f", camera.scale)).." pointers : ["..(#pointers.moved)..","..(#pointers.pressed)..","..(#pointers.released).."]")
   love.graphics.print("#tris "..triangle_count, 10, 30)
   Hammer:draw()
end
