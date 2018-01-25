
Signal = require 'vendor.signal'
Gamestate = require "vendor.gamestate"
Camera = require "vendor.camera"
inspect = require "vendor.inspect"

InterActiveMovieMode = require "modes.interactive_movie"

StageMode = require "modes.stage"
DragMode = require "modes.drag_item"
DrawMode = require "modes.draw_item"

ItemMode = require "modes.edit_item"
PolygonMode = require "modes.edit_polygon"
PolyLineMode = require "modes.edit_polyline"
SmartLineMode = require "modes.edit_smartline"

Mesh3dMode = require "modes.edit_mesh3d"
RectMode = require "modes.edit_rect"

RopeMode = require "modes.edit_rope"
Hammer = require "hammer"

utils = require "utils"
local shapes = require "shapes"
poly = require 'poly'

local pointers = require "pointer"

local a = require "vendor.affine"
--------------------------------

SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768




function parentize(root)
   if root.children then
      for i=1, #root.children do
         root.children[i].parent = root
         parentize(root.children[i]);
      end
   end
end

function updateGraph(root, dt)

   if root.pivot then
      local T = a.trans(root.pos.x, root.pos.y)
      local P = a.trans(-root.pivot.x, -root.pivot.y)
      local R = a.rotate(root.rotation or 0)
      local S = a.scale(root.scale and root.scale.x or 1, root.scale and root.scale.y or 1)

      root.local_trans = T*R*S*P
   else
      local T = a.trans(root.pos.x, root.pos.y)
      local R = a.rotate(root.rotation or 0)
      local S = a.scale(root.scale and root.scale.x or 1, root.scale and root.scale.y or 1)

      root.local_trans = T*R*S
   end

   if not root.world_pos then
      root.world_pos = {{x=0,y=0,z=0,rot=0,scaleX=1,scaleY=1}}

   end

   if root.parent then
      root.world_trans = root.parent.world_trans * root.local_trans

      root.inverse = a.inverse(root.world_trans)

      root.world_pos.rot = (root.rotation or 0) + root.parent.world_pos.rot
      if root.scale then
         root.world_pos.scaleX = root.parent.world_pos.scaleX * root.scale.x
         root.world_pos.scaleY = root.parent.world_pos.scaleY * root.scale.y
      else
         root.world_pos.scaleX = root.parent.world_pos.scaleX
         root.world_pos.scaleY = root.parent.world_pos.scaleY
      end
   else
      root.world_trans = root.local_trans
      root.world_pos.rot = root.rotation or 0
      root.world_pos.scaleX = (root.scale and root.scale.x) or 1
      root.world_pos.scaleY = (root.scale and root.scale.y) or 1
   end







   --if root.dirty then
   if root.type and root.dirty then
      --print(root.type.." ("..(root.id or "?")..") is dirty at :"..(spent_time+dt))
      if root.dirty_types then
         for i=1, #root.dirty_types do
            --print(root.dirty_types[i])
         end
      else
      end

      --local shape = shapes.makeShape({type="simplerect",pos={x=0,y=0},data=root.data})
      local shape

      shape = shapes.makeShape({type=root.type, pos={x=0,y=0},data=root.data})

      shape = shapes.scaleShape(shape, root.world_pos.scaleX, root.world_pos.scaleY)
      if root.rotation or root.world_pos.rot then
         shape = shapes.rotateShape(0, 0, shape, root.world_pos.rot)
      end
      --print(inspect(root.world_pos))
      local x,y = root.world_trans(0,0)
      --print(x,y, root.pos.x, root.pos.y)

      shape = shapes.transformShape(x,y,shape,root)

      root.triangles = poly.triangulate(root.type, shape)
      root.dirty = false

      -- your children get updated too!
      if root.children then
         for i=1,#root.children do
            root.children[i].dirty = true
         end
      end

   end


   if root.children then
      for i=1, #root.children do
         updateGraph(root.children[i], dt)
      end
   end
end


function updateSceneGraph(init, root, dt)
   parentize(root)
   updateGraph(root, dt)
end


function initWorld(world)
   world.dirty = true
   if world.children then
      for i=1, #world.children do
         initWorld(world.children[i])
      end
   end
end


function love.load()
   if arg[#arg] == "-debug" then require("mobdebug").start() end
   love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, {resizable=true, vsync=true, fullscreen=false})

   helvetica = love.graphics.newFont("resources/helvetica_bold.ttf", 18)
   --helvetica = love.graphics.newFont("resources/sansmono.ttf", 14)

   love.graphics.setFont(helvetica)
   Hammer.pointers = pointers

   world = {
      pos={x=0,y=0,z=0},
      id="world",
      children={
         -- {
         --    type="simplerect",
         --    id="opa-oom",
         --    pos={x=0,y=0,z=0},
         --    rotation=0,
         --    data={w=100, h=100},
         --    world_pos={x=0,y=0,z=0,rot=0},
         -- },
         -- {
         --    type="simplerect",
         --    id="opa-oom2",
         --    pos={x=500,y=0,z=0},
         --    rotation=0,
         --    data={w=100, h=100},
         --    world_pos={x=0,y=0,z=0,rot=0},
         -- },
         -- {
         --    type="simplerect",
         --    id="opa-oom3",
         --    pos={x=0,y=600,z=0},
         --    rotation=0,
         --    data={w=100, h=100},
         --    world_pos={x=0,y=0,z=0,rot=0},
         -- },
         -- {
         --    type="simplerect",
         --    id="opa-oom4",
         --    pos={x=10,y=600,z=0},
         --    rotation=0,
         --    data={w=100, h=100},
         --    world_pos={x=0,y=0,z=0,rot=0},
         -- },
         -- {
         --    type="simplerect",
         --    id="opa",
         --    pivot={x=-150,y=-150},
         --    pos={x=0,y=0,z=0},
         --    scale={x=2, y=2},
         --    rotation=0,
         --    data={w=300, h=300},
         --    children={
         --       {
         --          type="simplerect",
         --          id="papa",
         --          pos={x=150,y=0,z=0},
         --          scale={x=1.5, y=1.5},
         --          data={w=200, h=200},
         --          rotation=math.pi/13 ,

         --          children={
         --             {
         --                type="simplerect",
         --                id="jongen",
         --                scale={x=1.5, y=1.5},
         --                pos={x=100,y=0,z=0},
         --                data={w=100, h=100},
         --                rotation=0,
         --             }
         --          }
         --       }
         --    }
         -- },

         -- {
         --    type="mesh3d",
         --    pos={x=0,y=0,z=0},
         --    data={width=3, height=10, cellwidth=50, cellheight=50}
         -- },
         -- {
         --    type="rope",
         --    pos={x=100,y=100,z=0},
         --    rotation=0,
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
         --  },
         --  children={
         --     {type="rect", rotation=0, pos={x=30, y=10, z=0}, world_pos={x=0,y=0,z=0,rot=0}, data={w=200, h=200, radius=50, steps=8}}
         --  }
         -- },


         {
            type="smartline",
            pos={x=0,y=0,z=0},
            data={
               join="miter",
               use_relative_rotation = true,
               coords={0,0,150,100,250,400,500,700,600,800,750,900,810,1000},
               world_rotations={},
               relative_rotations={},
               lengths={},
               thicknesses={20,10,30,20,20, 10,20,20,20}
            }
         },


         -- {
         --    type="polygon", pos={x=0, y=0, z=0},
         --    data={ steps=3,  points={{x=0,y=0}, {cx=100, cy=-100},{cx=200, cy=-100},{cx=300, cy=-100}, {x=200,y=0}, {x=200, y=200}, {x=0, y=250}} },
         --    children={
         --       --{type="rect", rotation=0, pos={x=30, y=10, z=0}, world_pos={x=0,y=0,z=0,rot=0}, data={w=200, h=200, radius=50, steps=8}},
         --       {type="rope",
         --       pos={x=100,y=100,z=0},
         --       rotation=0,
         --       data={
         --          join="miter",
         --          relative_rotation = true,
         --          rotations={0, 0, 0, 0, 0, 0,0,0,0},
         --          lengths={120,120,100,100,100,100,100,100 },
         --          thicknesses={20,50,60,70,70,70,70,60,20},
         --       }},
         --       {
         --          type="polyline",
         --          pos={x=0,y=0,z=0},
         --          data={coords={0,0,-10,-100 , 50, 50, 100,50,10,200}, join="miter", half_width=50, thicknesses={10,20,30,40,50}  }

         --       },
         --       {
         --          type="rect", rotation=0, pivot={x=0,y=0}, pos={x=300, y=100, z=0}, data={w=200, h=200, radius=50, steps=8}
         --       },

         --    },
         -- },
         -- {
         -- {
         --    type="rect", rotation=0, pivot={x=0,y=0}, pos={x=300, y=100, z=0},
         --    data={w=200, h=200, radius=50, steps=8}
         -- },

         -- {
         --    type="rect", rotation=0, pivot={x=0,y=0}, pos={x=300, y=100, z=0}, data={w=200, h=200, radius=50, steps=8},
         --    children = {
         --       {type="rect", rotation=0, pivot={x=0,y=0}, pos={x=300, y=100, z=0}, data={w=100, h=100, radius=100, steps=8}},
         --       {type="circle", pos={x=500, y=100, z=0}, data={radius=200, steps=2}},
         --       {type="star", rotation=0.1, pos={x=0, y=300, z=0}, data={sides=8, r1=100, r2=200, a1=0, a2=0}},

         --    }
         -- },

      },
   }
   initWorld(world)
   spent_time = 0

   updateSceneGraph(true, world, 0)
   camera = Camera(0, 0)
   Gamestate.registerEvents()
   Gamestate.switch(StageMode)
   --Gamestate.switch(InteractiveMovieMode)

   Signal.register(
      'switch-state',
      function(state, data)
         local State = nil
         if state == "stage" then
            --State = InteractiveMovieMode
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
         elseif state == "edit-rect" then
            State = RectMode
         elseif state == "edit-smartline" then
            State = SmartLineMode
         elseif state == "interactive-movie" then
            State = InterActiveMovieMode
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


function drawSceneGraph(root)
   local triangle_count = 0
   --print(root.type)

   for i=1, #root.children do
      if root.children[i].children then
         triangle_count = triangle_count +  drawSceneGraph(root.children[i])
      end

      if root.children[i].triangles  then
         for j=1, #root.children[i].triangles do
            love.graphics.setColor(math.random()*0 + 100, 155+ math.random()*00 + 20,55, 155)
            love.graphics.polygon("fill", root.children[i].triangles[j])
            triangle_count = triangle_count + 1
         end
      else
         print("child at index "..i.." has no triangles.", root.children[i].type)
      end
   end
   return triangle_count
end


function love.update(dt)
   spent_time = spent_time + dt
   if love.keyboard.isDown("escape") then love.event.quit() end
   updateSceneGraph(false, world, dt)
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

function setPivot(me)
   local pressed = Hammer.pointers.pressed[1]
   local wxr,wyr = camera:worldCoords(pressed.x, pressed.y)
   local tx,ty = me.child.world_trans(0,0)
   local diffx = (wxr - tx)/me.child.world_pos.scaleX
   local diffy = (wyr - ty)/me.child.world_pos.scaleY
   local t2x, t2y = utils.rotatePoint(diffx, diffy, 0, 0, -me.child.world_pos.rot)
   if not me.child.pivot then
      me.child.pivot = {x=0,y=0}
   end

   local pivotdx = t2x - (me.child.pivot.x)
   local pivotdy = t2y - (me.child.pivot.y)
   pivotdx,pivotdy = utils.rotatePoint(pivotdx, pivotdy, 0, 0, me.child.world_pos.rot)
   me.child.pos.x = me.child.pos.x + pivotdx
   me.child.pos.y = me.child.pos.y + pivotdy

   me.child.pivot.x = t2x
   me.child.pivot.y = t2y

   me.setPivot=false

end
