-- https://awesome.naquadah.org/wiki/Active_RAM
   local wibox = require("wibox")
   local awful = require("awful")
   local gears = require("gears")
   
   activeram_widget = wibox.widget.textbox()
   activeram_widget:set_align("right")
   
   function update_activeram(widget)
       local active, total
 	for line in io.lines('/proc/meminfo') do
 		for key, value in string.gmatch(line, "(%w+): +(%d+).+") do
 			if key == "Active" then active = tonumber(value)
 			elseif key == "MemTotal" then total = tonumber(value) end
 		end
 	end
   
       widget:set_markup(string.format(" %.1f",(100*active/total)) .. "%")
   end
   
   update_activeram(activeram_widget)
   
   local activeramtimer = gears.timer.start_new( 10, function () update_activeram(activeram_widget) return true end )
