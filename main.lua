
--[[

   The editor lets you move around polygons on a stage.
   You can also add and remove new polygons
   The individual polygons can be modified too.

   Modes:
   - stage mode, here you drag around the camera on the stage, alos maybe move around items
   - item mode, here you edit the individual properties of an item

   an item looks like
   {type="rect/circle/group/rounded/star/etc", pos={x,y,z}}



]]--

Signal = require 'vendor.signal'
Gamestate = require "vendor.gamestate"
Camera = require "vendor.camera"
local inspect = require "vendor.inspect"
--local bitser = require 'vendor.bitser'

stageMode = require "modes.stage"
dragMode = require "modes.drag_item"
itemMode = require "modes.edit_item"

local utils = require "utils"
local shapes = require "shapes"
poly = require 'poly'



-- function rotatePoint(x,y,cx,cy,theta)
--    local px = math.cos(theta) * (x-cx) - math.sin(theta) * (y-cy) + cx
--    local py = math.sin(theta) * (x-cx) + math.cos(theta) * (y-cy) + cy
--    return px,py
-- end

function rotateShape(cx, cy, shape, theta)
   local result = {}

   local costheta = math.cos(theta)
   local sintheta = math.sin(theta)
   local x,y,nx,ny

   for i=1, #shape, 2 do
      x = shape[i +0]
      y = shape[i+1]
      nx = costheta * (x-cx) - sintheta * (y-cy) + cx
      ny = sintheta * (x-cx) + costheta * (y-cy) + cy
      result[i+0] = nx
      result[i+1] = ny
   end

   return result
end



function love.load()
   if arg[#arg] == "-debug" then require("mobdebug").start() end
   love.window.setMode(1024, 768, {resizable=true, vsync=true, fullscreen=false})

   world = {
      children={
         {type="rect", rotation=0, pos={x=300, y=100, z=0}, data={w=200, h=200}},
         {type="circle", pos={x=500, y=100, z=0}, data={radius=200}},
         {type="star", rotation=0.1, pos={x=0, y=300, z=0}, data={sides=8, r1=100, r2=200, a1=0, a2=0}},


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
         shape = rotateShape(c.pos.x, c.pos.y, shape, c.rotation)
      end

      c.triangles = poly.triangulate(shape)
   end

   camera = Camera(0, 0)
   Gamestate.registerEvents()
   Gamestate.switch(stageMode)

   Signal.register('switch-state',
                   function(state, data)
                      local realState = nil
                      if state == "stage" then realState=stageMode end
                      if state == "drag-item" then realState=dragMode end
                      if state == "edit-item" then realState=itemMode end
                      Gamestate.switch(realState, data)
                   end)
end

function love.keypressed(key)
   if key == "s" then
      --serializedString = bitser.dumps(world)
      --love.filesystem.write("filename.bin", serializedString)
      local serialized = inspect(world)
      love.filesystem.write("filename.txt", serialized)
   end
   if key == "o" then
      love.system.openURL("file://"..love.filesystem.getSaveDirectory())
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
            shape = rotateShape(c.pos.x, c.pos.y, shape, c.rotation)
         end
         c.triangles = poly.triangulate(shape)
      end
   end

end

function love.draw()
   --love.graphics.print("press <O> to open the library (drop the file on the stage), <S> to save the current stage")
   love.graphics.setColor(255,255,255)
   love.graphics.print("camera "..camera.x..", "..camera.y.." zoom:"..camera.scale)
   camera:attach()
   for i=1, #world.children do
      for j=1, #world.children[i].triangles do
         love.graphics.setColor(255,love.math.random()*255,0)
         love.graphics.polygon("fill", world.children[i].triangles[j])
      end
   end

   camera:detach()

end
