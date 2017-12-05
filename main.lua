--[[
   todo polygon is broken; cannot add new vertices
]]--

local suit = require 'vendor.suit'
Signal = require 'vendor.signal'
Gamestate = require "vendor.gamestate"
Camera = require "vendor.camera"
local inspect = require "vendor.inspect"

StageMode = require "modes.stage"
DragMode = require "modes.drag_item"
ItemMode = require "modes.edit_item"
PolygonMode = require "modes.edit_polygon"

local utils = require "utils"
local shapes = require "shapes"
poly = require 'poly'

-- storage for text input
local input = {text = ""}
local slider = {value = 1, min = 0, max = 2}
local checkbox = {checked = true, text="stuff"}

function love.load()
   if arg[#arg] == "-debug" then require("mobdebug").start() end
   love.window.setMode(1024, 768, {resizable=true, vsync=true, fullscreen=false})

   icon_font = love.graphics.newFont("icons.ttf", 30)
   helvetica = love.graphics.newFont("helvetica_bold.ttf", 18)

   world = {
      children={
         {
            type="rope",
            pos={x=100,y=100,z=0},
            data={
               relative_rotation = false,
               rotations={-math.pi/2,-math.pi/2 -0.2,-math.pi/2 -0.4,-math.pi/2},
               lengths={120,120,100,50},
               thicknesses={10,80,30,40,10},
            }
         },
         {type="rope",
          pos={x=-100,y=100,z=0},
          data={
             relative_rotation = true,
             rotations={-math.pi/2,-0.8,-0.8,0.8},
             lengths={120,120,100,50},
             thicknesses={40,40,30,20},
          }
         },


         {type="polyline", pos={x=100,y=100,z=0}, data={coords={0,0,-10,-100 , 50, 50, 100,50,10,200,0,0}, join="miter", half_width=5  }},
         {type="rect", rotation=0, pos={x=300, y=100, z=0}, data={w=200, h=200, radius=50, steps=8}},
         {type="circle", pos={x=500, y=100, z=0}, data={radius=200, steps=2}},
         {type="star", rotation=0.1, pos={x=0, y=300, z=0}, data={sides=8, r1=100, r2=200, a1=0, a2=0}},
         {type="polygon", pos={x=0, y=0, z=0}, data={ steps=3,  points={{x=0,y=0}, {cx=100, cy=-100},{cx=200, cy=-100},{cx=300, cy=-100}, {x=200,y=0}, {x=200, y=200}, {x=0, y=250}} }}
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
         elseif state == "edit-item" then
            State = ItemMode
         elseif state == "edit-polygon" then
            State = PolygonMode
         end
         Gamestate.switch(State, data)
      end
   )

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
   	suit.keypressed(key)

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
   love.graphics.setFont(helvetica)

   suit.layout:reset(10,100)
   suit.layout:padding(10,10)
	-- put an input widget at the layout origin, with a cell size of 200 by 30 pixels
	suit.Input(input, suit.layout:row(200,30))

	-- put a label that displays the text below the first cell
	-- the cell size is the same as the last one (200x30 px)
	-- the label text will be aligned to the left
	suit.Label("Hello, "..input.text, {align = "left", color={255,0,0}}, suit.layout:row())

	-- put an empty cell that has the same size as the last cell (200x30 px)
	-- put a button of size 200x30 px in the cell below
	-- if the button is pressed, quit the game
    --local str =  '\\u{e87C}'
    --local str= utf8(0xE869)
    love.graphics.setFont(icon_font)

    local str = utf8(0xE40A)
	if suit.Button(str, suit.layout:row()).hit then
		love.event.quit()
	end
    --love.graphics.setFont(love.graphics.newFont(18))
   love.graphics.setFont(helvetica)

    if suit.Button("Blaargh", suit.layout:row()).hit then
       suit.Label("Urgh?", suit.layout:row())

	end

    suit.layout:left(300,30)
    suit.layout:row()
    --suit.layout:reset()

	suit.Button("whaja", suit.layout:col(100,30))
	suit.Button("onka", suit.layout:col(30,30))
    suit.Button("duff", suit.layout:col(50,30))

    suit.layout:left(140,30)
    suit.layout:row(200,30)



    suit.Slider(slider, suit.layout:row())
    suit.Checkbox(checkbox, suit.layout:row())

    suit.Label(tostring(slider.value), suit.layout:row())
end

function love.draw()
   love.graphics.setColor(255,255,255)
   love.graphics.print("camera " .. math.floor(camera.x) .. ", " .. math.floor(camera.y) .. "," .. tonumber(string.format("%.3f", camera.scale)))
   camera:attach()
   local triangle_count = 0
   for i=1, #world.children do
      if world.children[i].triangles  then
         for j=1, #world.children[i].triangles do
            love.graphics.setColor(255,200 + math.random()*55,255, 100)
            love.graphics.polygon("fill", world.children[i].triangles[j])
            triangle_count = triangle_count + 1
         end
      end
   end


   camera:detach()
   love.graphics.print("#tris "..triangle_count, 10, 30)

   suit.draw()

end

function love.textedited(text, start, length)
    -- for IME input
    suit.textedited(text, start, length)
end

function love.textinput(t)
	-- forward text input to SUIT
	suit.textinput(t)
end
