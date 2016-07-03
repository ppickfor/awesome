-- https://awesome.naquadah.org/wiki/Move_Mouse
-- set the desired pixel coordinates:
--  if your screen is 1024x768 the this line sets the bottom right.
safeCoords = {x=(screen[1].geometry.width), y=( screen[1].geometry.height)}
-- local safeCoords = {x=1000, y=100}
--  this line sets top middle(ish).
-- Flag to tell Awesome whether to do this at startup.
local moveMouseOnStartup = true

-- Simple function to move the mouse to the coordinates set above.
function moveMouse(x_co, y_co)
    mouse.coords({ x=x_co, y=y_co })
end

-- Bind ''Meta4+Ctrl+m'' to move the mouse to the coordinates set above.
--   this is useful if you needed the mouse for something and now want it out of the way
-- keybinding({ modkey, "Control" }, "m", function() moveMouse(safeCoords.x, safeCoords.y) end):add()

-- Optionally move the mouse when rc.lua is read (startup)
if moveMouseOnStartup then
        moveMouse(safeCoords.x, safeCoords.y)
end
