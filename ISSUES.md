Error: polyline.lua:204: attempt to perform arithmetic on a nil value

Error: utils.lua:256: attempt to perform arithmetic on local 'distance' (a nil value)
stack traceback:
        vendor/gamestate.lua:89: in function '__mul'
        utils.lua:256: in function 'moveAtAngle'
        utils.lua:279: in function 'calculateCoordsFromRotationsAndLengths'
        modes/edit_smartline.lua:285: in function 'update'
