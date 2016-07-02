local wibox = require("wibox")
local awful = require("awful")
   
local io = io
local math = math
local naughty = naughty
local beautiful = beautiful
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

function get_bat_state (adapter)
    local fcha = io.open("/sys/class/power_supply/"..adapter.."/charge_now")
    local fcap = io.open("/sys/class/power_supply/"..adapter.."/charge_full")
    local fcur = io.open("/sys/class/power_supply/"..adapter.."/current_now")
    local fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
    local cha = fcha:read()
    local cap = fcap:read()
    local cur = fcur:read()
    local sta = fsta:read()
    fcha:close()
    fcap:close()
    fcur:close()
    fsta:close()
    local battery = math.floor(cha * 100 / cap)
    if cur ~= cur or cha ~= cha or cap ~= cap or math.floor(cur) == 0 then
        sta = "Unknown"
    else
    local battery = math.floor(cha * 100 / cap)
    end
    -- dbg( { cur, cha, cap, sta } )
    if sta:match("Charging") then
        time = hrstotime((cap-cha)/cur)
        dir = 1
    elseif sta:match("Discharging") then
        time = hrstotime(cha/cur)
        dir = -1
    else
        dir = 0
        battery = ""
        time = ""
    end
    return battery, dir, time
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


function batclosure (adapter)
    local nextlim = limits[1][1]
    return function ()
        local prefix = "⚡"
        local battery, dir, time = get_bat_state(adapter)
        if dir == -1 then
            dirsign = "↓"
            prefix = "Bat: "
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

batterywidget = wibox.widget.textbox()
batterywidget:set_align("right")
   
function update_battery(widget)
  local bat = batclosure("BAT1")
  widget:set_markup(bat())
end

update_battery(batterywidget)

battimer = timer({ timeout = 10 })
battimer:connect_signal("timeout", function () update_battery(batterywidget) end)
battimer:start()
