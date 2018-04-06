
inspect = require "inspect"




function love.load()
   mn = {
      "HappyLife",
      "HappyWeek",
      "HappyDay",
      "HappyNow",
      "Physical",
      "Energy",
      "Comfort",
      "Hunger",
      "Hygiene",
      "Bladder",
      "Mental",
      "Alertness",
      "Stress",
      "Environment",
      "Social",
      "Entertained"
   }

   m = {
      HappyLife    = 1,
      HappyWeek    = 2,
      HappyDay     = 3,
      HappyNow     = 4,
      Physical     = 5,
      Energy       = 6,
      Comfort      = 7,
      Hunger       = 8,
      Hygiene      = 9,
      Bladder      = 10,
      Mental       = 11,
      Alertness    = 12,
      Stress       = 13,
      Environment  = 14,
      Social       = 15,
      Entertained  = 16
   }
   guy = {
      motives = { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
      old_motives= { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 },
   }

   DAYTICKS   = 720
   WEEKTICKS  = 5040

   clock = {hours=8, minutes=0}
   initMotives(guy)
end

function initMotives(guy)
   for i=1, #guy.motives do
      guy.motives[i] = 0
   end
   guy.motives[m.Energy]    = 10
   guy.motives[m.Alertness] = 20
   guy.motives[m.Hunger]    = -40
end




function simMotives(guy)
   local tem
   -- Energy
   if guy.motives[m.Energy] > 0 then
      if guy.motives[m.Alertness] > 0 then
         guy.motives[m.Energy] = guy.motives[m.Energy] - guy.motives[m.Alertness]/100
      else
         guy.motives[m.Energy] =  guy.motives[m.Energy] - (guy.motives[m.Alertness]/100) * ((100 - guy.motives[m.Energy])/50)
      end
   else
      if guy.motives[m.Alertness] > 0 then
         guy.motives[m.Energy] = guy.motives[m.Energy] - (guy.motives[m.Alertness]/100) * ((100 + guy.motives[m.Energy])/50)
      else
         guy.motives[m.Energy] =  guy.motives[m.Energy] - guy.motives[m.Alertness]/100
      end
   end
   -- had some food
   if guy.motives[m.Hunger] > guy.old_motives[m.Hunger] then
      tem = guy.motives[m.Hunger] - guy.old_motives[m.Hunger]
      guy.motives[m.Energy] = guy.motives[m.Energy] + (tem/4)
   end

   -- comfort
   if guy.motives[m.Bladder] < 0 then
      guy.motives[m.Comfort] = guy.motives[m.Comfort] + (guy.motives[m.Bladder]/10)  -- max -10
   end
   if guy.motives[m.Hygiene] < 0 then
      guy.motives[m.Comfort] = guy.motives[m.Comfort] + (guy.motives[m.Hygiene]/20)  --max -5
   end
   if guy.motives[m.Hunger] < 0 then
      guy.motives[m.Comfort] = guy.motives[m.Comfort] + (guy.motives[m.Hunger]/20)  --max -5
   end
   guy.motives[m.Comfort] = guy.motives[m.Comfort] - (guy.motives[m.Comfort] * guy.motives[m.Comfort] * guy.motives[m.Comfort] )/10000

   -- hunger
   tem = ((guy.motives[m.Alertness]+100)/200) * ((guy.motives[m.Hunger]+100)/100)
   if guy.motives[m.Stress] < 0 then
      guy.motives[m.Hunger] = guy.motives[m.Hunger] + (guy.motives[m.Stress]/100) * ((guy.motives[m.Hunger]+100)/100)
   end
   if guy.motives[m.Hunger] < -99 then
      print("You ded!")
      guy.motives[m.Hunger] = 80
   end

   -- hygiene
   if guy.motives[m.Alertness] > 0 then
      guy.motives[m.Hygiene] = guy.motives[m.Hygiene] - .3
   else
      guy.motives[m.Hygiene] = guy.motives[m.Hygiene] - .1
   end
   if guy.motives[m.Hygiene] < -97 then
      print("You so dirty you clen!")
      guy.motives[m.Hygiene] = 80
   end

   --bladder
   if guy.motives[m.Alertness] > 0 then
      guy.motives[m.Bladder] = guy.motives[m.Bladder] - .4
   else
      guy.motives[m.Bladder] = guy.motives[m.Bladder] - .2
   end
   if guy.motives[m.Hunger] > guy.old_motives[m.Hunger] then
      tem = guy.motives[m.Hunger] - guy.old_motives[m.Hunger]
      guy.motives[m.Bladder] = guy.motives[m.Bladder] - (tem/4)
   end
   if guy.motives[m.Bladder] < -97 then
      if guy.motives[m.Alertness] < 0 then
         print("You have wet your bed")
      else
         print("You have soiled the floor")
      end
      guy.motives[m.Bladder] = 90
   end

   -- alertness
   if guy.motives[m.Alertness] > 0 then
      tem = (100 - guy.motives[m.Alertness]) / 50
   else
      tem = (guy.motives[m.Alertness] + 100) / 50
   end
   if guy.motives[m.Energy] > 0 then
      if guy.motives[m.Alertness] > 0 then
         guy.motives[m.Alertness] = guy.motives[m.Alertness] + (guy.motives[m.Energy] / 100) * tem
      else
         guy.motives[m.Alertness] = guy.motives[m.Alertness] + (guy.motives[m.Energy] / 100)
      end
   else
      if guy.motives[m.Alertness] > 0 then
         guy.motives[m.Alertness] = guy.motives[m.Alertness] + (guy.motives[m.Energy] / 100)
      else
         guy.motives[m.Alertness] = guy.motives[m.Alertness] + (guy.motives[m.Energy] / 100) * tem
      end
   end
   if guy.motives[m.Bladder] < -50 then
      guy.motives[m.Alertness] =  guy.motives[m.Alertness] - (guy.motives[m.Bladder]/100) * tem
   end

   -- stress
   guy.motives[m.Stress] = guy.motives[m.Stress] + guy.motives[m.Comfort]/10
   guy.motives[m.Stress] = guy.motives[m.Stress] + guy.motives[m.Entertained]/10
   guy.motives[m.Stress] = guy.motives[m.Stress] + guy.motives[m.Environment]/15
   guy.motives[m.Stress] = guy.motives[m.Stress] + guy.motives[m.Social]/20
   if guy.motives[m.Alertness] < 0 then
      guy.motives[m.Stress] = guy.motives[m.Stress] / 3
   end
   guy.motives[m.Stress] = guy.motives[m.Stress] - (guy.motives[m.Stress] * guy.motives[m.Stress] * guy.motives[m.Stress])/10000

   if guy.motives[m.Stress] < 0 then
      if (math.random()*30 - 100)  > guy.motives[m.Stress] then
         if (math.random()*30 - 100)  > guy.motives[m.Stress] then
            print("Tantrum time!")
            changeMotive(guy, m.Stress, 20)
         end
      end
   end

   -- environment

   -- social

   -- entertained
   if guy.motives[m.Alertness] < 0 then
      guy.motives[m.Entertained] = guy.motives[m.Entertained]/2
   end

   -- physical
   tem = guy.motives[m.Energy]
   tem = tem + guy.motives[m.Comfort]
   tem = tem + guy.motives[m.Hunger]
   tem = tem + guy.motives[m.Hygiene]
   tem = tem + guy.motives[m.Bladder]
   tem = tem / 5
   if tem > 0 then
      tem = 100 - tem
      tem = (tem * tem) / 100
      tem = 100 - tem
   else
      tem = 100 + tem
      tem = (tem * tem) / 100
      tem = tem -100
   end
   guy.motives[m.Physical] = tem

   -- mental
   tem = tem + guy.motives[m.Stress]
   tem = tem + guy.motives[m.Stress]
   tem = tem + guy.motives[m.Environment]
   tem = tem + guy.motives[m.Social]
   tem = tem + guy.motives[m.Entertained]
   tem = tem/5
   if tem > 0 then
      tem = 100 - tem
      tem = (tem * tem) / 100
      tem = 100 - tem
   else
      tem = 100 + tem
      tem = (tem * tem) / 100
      tem = tem -100
   end
   guy.motives[m.Mental] = tem

   -- avg happy
   guy.motives[m.HappyNow] = (guy.motives[m.Physical]+guy.motives[m.Mental]/2 )
   guy.motives[m.HappyDay] = ((guy.motives[m.HappyDay] * (DAYTICKS-1)) + guy.motives[m.HappyNow]) / DAYTICKS
   guy.motives[m.HappyWeek] = ((guy.motives[m.HappyWeek] * (WEEKTICKS-1)) + guy.motives[m.HappyNow]) / WEEKTICKS
   guy.motives[m.HappyLife] = ((guy.motives[m.HappyLife] * 9) + guy.motives[m.HappyWeek]) / 10

   guy.motives[m.HappyNow] = (guy.motives[m.Physical]+guy.motives[m.Mental]/2 )

end


function changeMotive(guy, motive, value)
   guy.motives[motive] = guy.motives[motive] + value
   if guy.motives[motive] > 100 then guy.motives[motive] = 100 end
   if guy.motives[motive] < -100 then guy.motives[motive] = -100 end

end


function updateClock(dt)
   local new_minutes = clock.minutes + (2 * dt * 30)
   local hasTicked = false
   if math.floor(new_minutes) ~= math.floor(clock.minutes) then
      hasTicked = true
   end

   clock.minutes = new_minutes
   if clock.minutes > 58 then
      clock.minutes = 0
      clock.hours = clock.hours + 1
      if clock.hours > 24 then clock.hours = 1 end
   end

   return hasTicked
end


function love.update(dt)
   if love.keyboard.isDown("escape") then love.event.quit() end

   if updateClock(dt) then
      simMotives(guy)
   end

end

function love.draw()
   love.graphics.print(clock.hours..":"..math.floor(clock.minutes))

   for i=1, #guy.motives do
      love.graphics.print(mn[i]..":"..guy.motives[i], 20, 20 * i)
   end

end
