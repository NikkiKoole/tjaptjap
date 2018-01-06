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

local pointers = require "pointer"

--------------------------------

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768

test = {
   type="something",
   id="my unique name",
   anchor={x=0.5, y=0.5},
   transform={x=0,y=0,z=0,scaleX=1,scaleY=1,rotation=0},
   data={value1=12, value2=23},
   children={},
}



function love.load()
   if arg[#arg] == "-debug" then require("mobdebug").start() end
   love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, {resizable=true, vsync=true, fullscreen=false})

   helvetica = love.graphics.newFont("resources/helvetica_bold.ttf", 18)
   love.graphics.setFont(helvetica)
   Hammer.pointers = pointers

   world = {
      world_pos={x=0,y=0,z=0,rot=0},
      pos={x=0,y=0,z=0},
      rotation=0,
      id="world",
      children={
         {
            type="simplerect",
            id="opa",
            pos={x=0,y=0,z=0},
            rotation=math.pi/4,
            data={w=300, h=300},
            world_pos={x=0,y=0,z=0,rot=0},

            children={
               {
                  type="simplerect",
                  id="papa",
                  pos={x=100,y=0,z=0},
                  data={w=200, h=200},
                  world_pos={x=0,y=0,z=0,rot=0},
                  rotation=0,

                  children={
                     {
                        type="simplerect",
                        id="jongen",
                        pos={x=110,y=110,z=0},
                        data={w=100, h=100},
                        world_pos={x=0,y=0,z=0,rot=0},
                        rotation=0,

                     }
                  }
               }
            }
         },

         -- {
         --    type="mesh3d",
         --    pos={x=0,y=0,z=0},
         --    data={width=3, height=10, cellwidth=50, cellheight=50}
         -- },
         -- {
         --    type="rope",
         --    pos={x=100,y=100,z=0},
         --    data={
         --       join="miter",
         --       relative_rotation = true,
         --       rotations={0, 0, 0, 0, 0, 0,0,0,0},
         --       lengths={120,120,100,100,100,100,100,100 },
         --       thicknesses={20,50,60,70,70,70,70,60,20},
         --    }
         -- },
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

   updateSceneGraph(true, world)

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

function updateSceneGraph(init, root)

   if root.children then
   for i=1, #root.children do
      root.children[i].world_pos.x = root.pos.x + root.world_pos.x
      root.children[i].world_pos.y = root.pos.y + root.world_pos.y
      root.children[i].world_pos.rot = root.rotation + root.world_pos.rot

      if (root.children[i].dirty or init) then
         root.children[i].dirty = false
         local c = root.children[i]
         c.world_pos.x = root.pos.x + root.world_pos.x
         c.world_pos.y = root.pos.y + root.world_pos.y
         c.world_pos.rot = root.rotation + root.world_pos.rot
         local shape = shapes.makeShape(c)
         if c.type=="simplerect" then
            shape = shapes.transformShape(c.world_pos.x, c.world_pos.y, shape)
         end
         if c.rotation then
            shape = shapes.rotateShape(c.pos.x, c.pos.y, shape, c.rotation+ c.world_pos.rot)
         end
         c.triangles = poly.triangulate(c.type, shape)
      end
      if root.children[i].children then
         updateSceneGraph(true, root.children[i])
      end

   end

   end
end
function drawSceneGraph(root)
   local triangle_count = 0
   for i=1, #root.children do
      if root.children[i].children then
         drawSceneGraph(root.children[i])
      end

      if root.children[i].triangles  then
         for j=1, #root.children[i].triangles do
            love.graphics.setColor(math.random()*200 + 100, 155+ math.random()*0 + 20,55, 155)
            love.graphics.polygon("fill", root.children[i].triangles[j])
            triangle_count = triangle_count + 1
         end
      else
         --print("child at index "..i.." has no triangles.")
      end
   end
   return triangle_count
end


function love.update(dt)
   if love.keyboard.isDown("escape") then love.event.quit() end
   updateSceneGraph(false, world)
end

function love.draw()
   camera:attach()
   local triangle_count = drawSceneGraph(world)
   camera:detach()

   love.graphics.setColor(255,255,255)
   love.graphics.print("camera " .. math.floor(camera.x) .. ", " .. math.floor(camera.y) .. "," .. tonumber(string.format("%.3f", camera.scale)).." pointers : ["..(#pointers.moved)..","..(#pointers.pressed)..","..(#pointers.released).."]")
   love.graphics.print("#tris "..triangle_count, 10, 30)
   Hammer:draw()
end
