--[[

]]--

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

function love.load()
   if arg[#arg] == "-debug" then require("mobdebug").start() end
   love.window.setMode(1024, 768, {resizable=true, vsync=true, fullscreen=false})

   world = {
      children={
         {type="rect", rotation=0, pos={x=300, y=100, z=0}, data={w=200, h=200, radius=50, steps=8}},
         {type="circle", pos={x=500, y=100, z=0}, data={radius=200, steps=2}},
         {type="star", rotation=0.1, pos={x=0, y=300, z=0}, data={sides=8, r1=100, r2=200, a1=0, a2=0}},
         {type="polygon", pos={x=0, y=0, z=0}, data={ points={{x=0,y=0}, {x=100,y=0}, {x=100, y=100}, {x=0, y=150}} }}
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
      c.triangles = poly.triangulate(shape)
      --print("triangle count for "..c.type.." = "..#c.triangles)
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
end

function love.filedropped(file)
   local data = love.filesystem.newFileData(file)
   world = loadstring("return "..data:getString())()
   --world = bitser.loadData(data:getPointer(), data:getSize())
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
            c.triangles = poly.triangulate(shape)
      end
   end
end

function love.draw()
   love.graphics.setColor(255,255,255)
   love.graphics.print("camera " .. math.floor(camera.x) .. ", " .. math.floor(camera.y) .. "," .. tonumber(string.format("%.3f", camera.scale)))
   camera:attach()
   local triangle_count = 0
   for i=1, #world.children do
      if world.children[i].triangles  then
         for j=1, #world.children[i].triangles do
            love.graphics.setColor(255,255,255, 100)
            love.graphics.polygon("fill", world.children[i].triangles[j])
            triangle_count = triangle_count + 1
         end
      end
   end


   camera:detach()
   love.graphics.print("#tris "..triangle_count, 10, 30)
end
