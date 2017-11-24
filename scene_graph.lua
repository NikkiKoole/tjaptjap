function getDisplayObject(img, quad, x, y, pivotX, pivotY)
   return {
      img = img,
      quad = quad,
      pivot = {x=pivotX, y=pivotY},
      local_transform = {
         position = {x=x, y=y},
         scale = {x=1, y=1},
         radian = 0,
      },
      world_transform = {
         position = {x=0, y=0},
         scale = {x=1, y=1},
         radian = 0,
      },
   }
end

function initWorldTransform(item)
   item.world_transform = {};
   item.world_transform.position = {x=0, y=0};
   item.world_transform.scale = {x=0, y=0};
   item.world_transform.radian = 0
end

function recursivePrintValues(root, prefix)
   print(prefix .. root.name)
   print(prefix .. "local transform")
   print(prefix .. root.local_transform.position.x);
   print(prefix .. root.local_transform.position.y);
   print(prefix .. root.local_transform.scale.x);
   print(prefix .. root.local_transform.scale.y);
   print(prefix .. root.local_transform.radian);
   print(prefix .. "world transform")
   print(prefix .. root.world_transform.position.x);
   print(prefix .. root.world_transform.position.y);
   print(prefix .. root.world_transform.scale.x);
   print(prefix .. root.world_transform.scale.y);
   print(prefix .. root.world_transform.radian);

   if (root.children) then
      for i, child in ipairs(root.children) do
         recursivePrintValues(child, prefix .. "    ")
      end
   end
end

function localToParent(parent, x, y)
   local px, py = x, y
   -- scale
   px, py = px*parent.world_transform.scale.x, py*parent.world_transform.scale.y
   -- rotate
   local ca = math.cos(parent.world_transform.radian)
   local sa = math.sin(parent.world_transform.radian)
   local tx = ca*px - sa*py
   local ty = sa*px + ca*py
   px, py = tx, ty
   -- translate
   px = px + parent.world_transform.position.x
   py = py + parent.world_transform.position.y
   return px, py
end

function recursiveDraw(root)
   if root.parent then
      x, y = localToParent(root.parent, root.local_transform.position.x, root.local_transform.position.y)
      scaleX = root.parent.world_transform.scale.x * root.local_transform.scale.x
      scaleY = root.parent.world_transform.scale.y * root.local_transform.scale.y
      radian = root.parent.world_transform.radian + root.local_transform.radian
   else
      x = root.local_transform.position.x
      y = root.local_transform.position.y
      scaleX = root.local_transform.scale.x
      scaleY = root.local_transform.scale.x
      radian = root.local_transform.radian
   end

   root.world_transform.position.x = x
   root.world_transform.position.y = y
   root.world_transform.scale.x = scaleX
   root.world_transform.scale.y = scaleY
   root.world_transform.radian = radian

   if root.color then
      r, g, b, a = love.graphics.getColor( )
      love.graphics.setColor(root.color[1],root.color[2],root.color[3], root.color[4] )
   end

   if root.img then
      if root.multiply then
         love.graphics.setBlendMode("multiply")
      elseif root.premultiply then
         love.graphics.setBlendMode("alpha", "premultiplied")
      else
         love.graphics.setBlendMode("alpha")
      end

      if (root.quad) then
         love.graphics.draw(root.img, root.quad, x, y, radian, scaleX, scaleY, root.pivot.x, root.pivot.y)

      else
         love.graphics.draw(root.img, x, y, radian, scaleX, scaleY, root.pivot.x, root.pivot.y)
         end
   end

   if (root.color) then
      love.graphics.setColor(r,g,b,a)
   end


   if root.children then
      for i, child in ipairs(root.children) do
         recursiveDraw(child)
      end
   end
end

function getIndex(array, item)
   for k,v in ipairs(array) do
      if v == item then return k end
   end
   return -1
end

function removeChild(parent, child)
   if not parent.children then return nil end
   index = getIndex(parent.children, child)
   if index > -1 then
      table.remove(parent.children, index)
      child.parent = nil
      return child
   end
   return nil
end

function addChild(parent, child)
   if not parent.children then
      parent.children = {}
   end
   table.insert(parent.children, child)
   child.parent = parent;
end


return {
   getDisplayObject = getDisplayObject,
   initWorldTransform = initWorldTransform,
   recursivePrintValues = recursivePrintValues,
   localToParent = localToParent,
   recursiveDraw = recursiveDraw,
   getIndex = getIndex,
   removeChild = removeChild,
   addChild = addChild
}
