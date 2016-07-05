-- https://awesome.naquadah.org/wiki/Closured_Battery_Widget
local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local lfs = require("lfs")
   
local io = io
local math = math
local tonumber = tonumber
local tostring = tostring
local print = print
local pairs = pairs

-- module("battery")

local limits = {{25, 5},
          {12, 3},
          { 7, 1},
            {0}}

function hrstotime(hrs)
	local h=math.floor(hrs)
	local m=((hrs-h)*60)
	local s=math.floor((m-math.floor(m))*60)
  	m=math.floor(m)
	local time = string.format("%d:%02d:%02d", h, m, s)
	return time
end

function get_bat_state (adapter, mains)
    local fcha = io.open("/sys/class/power_supply/"..adapter.."/energy_now")
    if not fcha then
      fcha = assert(io.open("/sys/class/power_supply/"..adapter.."/charge_now"))
    end
    local fcap = io.open("/sys/class/power_supply/"..adapter.."/energy_full")
    if not fcap then
      fcap = assert(io.open("/sys/class/power_supply/"..adapter.."/charge_full"))
    end
    local fcur = io.open("/sys/class/power_supply/"..adapter.."/power_now")
    if not fcur then
      fcur = assert(io.open("/sys/class/power_supply/"..adapter.."/current_now"))
    end
    local fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
    local fonline = assert(io.open("/sys/class/power_supply/" .. mains .. "/online"))
    local cha = fcha:read()
    local cap = fcap:read()
    local cur = fcur:read()
    local sta = fsta:read()
    local onl = fonline:read()
    fcha:close()
    fcap:close()
    fcur:close()
    fsta:close()
    local battery = math.floor(cha * 100 / cap)
    if cur ~= cur or cha ~= cha or cap ~= cap or sta ~= sta then
        sta = "Unknown"
    end
    -- dbg( { cur, cha, cap, sta } )
    if sta:match("Charging") then
        if math.floor(cur) ~= 0 then
          time = hrstotime((cap-cha)/cur)
        else
          time = ""
        end
        dir = 1
    elseif sta:match("Discharging") then
        if math.floor(cur) ~= 0 then
          time = hrstotime(cha/cur)
        else
          time = ""
        end
        dir = -1
    else
        dir = 0
        battery = ""
        time = ""
    end
    if onl:match("1") then
      online = "⚡"
    else
      online = ""
    end
    return online, battery, dir, time
end

function getnextlim (num)
    for ind, pair in pairs(limits) do
        lim = pair[1]; step = pair[2]; nextlim = limits[ind+1][1] or 0
        if num > nextlim then
            repeat
                lim = lim - step
            until num > lim
            if lim < nextlim then
                lim = nextlim
            end
            return lim
        end
    end
end


function batclosure (adapter, mains)
    local nextlim = limits[1][1]
    return function ()
        local online, battery, dir, time = get_bat_state(adapter, mains)
        local prefix = online
        if dir == -1 then
            dirsign = "↓"
            prefix = prefix .. "Bat: "
            prefix = prefix .. time
            if battery <= nextlim then
                naughty.notify({title = "⚡ Beware! ⚡",
                            text = "Battery charge is low ( ⚡ "..battery.."%)!",
                            timeout = 7,
                            position = "bottom_right",
                            fg = beautiful.fg_focus,
                            bg = beautiful.bg_focus
                            })
                nextlim = getnextlim(battery)
            end
        elseif dir == 1 then
            prefix = prefix .. time
            dirsign = "↑"
            nextlim = limits[1][1]
        else
            dirsign = ""
        end
        if dir ~= 0 then battery = battery.."%" end
        return " "..prefix.." "..dirsign..battery..dirsign.." "
    end
end

function update_battery(widget)
  widget:set_markup(bat())
end

-- find the first battery in power_supply
local battery, mains
for file in lfs.dir[[/sys/class/power_supply/]] do
	if file ~= "." and file ~= ".." then
		typef = io.open("/sys/class/power_supply/" .. file .. "/type")
		if typef then
			types = typef:read()
			if types:match("Battery") then
				battery = file
			end
			if types:match("Mains") then
				mains = file
			end
		end
	end
end

   
bat = batclosure(battery, mains)
if bat then
	batterywidget = wibox.widget.textbox()
	batterywidget:set_align("right")
	update_battery(batterywidget)

	battimer = timer({ timeout = 10 })
	battimer:connect_signal("timeout", function () update_battery(batterywidget) end)
	battimer:start()
end
