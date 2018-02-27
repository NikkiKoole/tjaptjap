TODO
-------
- make lines start from either end

- maybe just for now use solid colors only
- improve (make smaller) ui
- some ui that shows nested parent-child relations



interactivemovie L180 local button = Hammer:rectangle( "poly-handle"..i.."__"..j, 30, 30, {x=cx2-15, y=cy2-15, color=color})
whn you mess up those IDs (use ..i without the j ) the result is quite cool, mayeb use it as a feature ?

- combine all colors into one data structures (instead of 3 atm)
- make it possible to remove all triangle colors and all vertex colors

- make a game mode, 3 screens high, parallax scrolling, center cam on items, have some default tweens per thing and attach sounds, maybe use a bit of OOP here.
- blend flux animations
- use what we have now to experiment with flux and find issues
- duplicate (not really) the coloring function from polygon to smartlines
- make a mesh per thing
- nested scene graph logic.
- reintroduce the parallax scrolling on z
- add random polygons generator with some params maybe move the rect, srect, circle, star into that
- keyframe animation
- live recording animation
- movie mode; rotations, ?line coords?, ?vertices?
- You need a way to optionally close polygons. (the type of polygons with a center node (nice for individual triangles) )
