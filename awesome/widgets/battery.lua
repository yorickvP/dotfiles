-- Standard awesome library
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- widget library
local lain = require("lain")
local markup      = lain.util.markup


function hover_popup(widget, text)
  local cur_notification = nil

  local function remove_old()
    if cur_notification ~= nil then
      naughty.destroy(cur_notification)
      cur_notification = nil
    end
  end
  local function add_new()
      t = text()
      if t == nil then return end
      remove_old()
      cur_notification = naughty.notify({
          text    = t,
          timeout = 0,
          screen  = mouse.screen,
          opacity = 0.8,
          --ontop = true,
      })
  end
  widget:connect_signal("mouse::enter", add_new)
  widget:connect_signal("mouse::leave", remove_old)
end

-- battery
-- battery_widget = wibox.widget.textbox()
local battery = {
  icon   = wibox.widget.imagebox();
  widget = nil;
}
do
  local bat_state
  battery.widget = lain.widgets.bat({
    settings = function()
      bat_state = bat_now
      local icon_full  = icon_dir .. "/bat_full_01.png"
      local icon_low   = icon_dir .. "/bat_low_01.png"
      local icon_empty = icon_dir .. "/bat_empty_01.png"
      local statemap = {
        ["Unknown"] = "⌁";
        ["Full"] = "↯";
        ["Charging"] = "+";
        ["Discharging"] = "-";
      }
      local color = beautiful.white
      if bat_now.perc == "N/A" then
          perc = "AC "
      else
        if tonumber(bat_now.perc) < 10 then
          battery.icon:set_image(icon_empty)
          color = beautiful.lpink
        elseif tonumber(bat_now.perc) < 30 then
          battery.icon:set_image(icon_low)
          color = beautiful.lpink
        else
          battery.icon:set_image(icon_full)
          color = beautiful.dgreen
        end
        perc = statemap[bat_now.status] .. bat_now.perc .. "%"
      end
      widget:set_markup(markup(color, perc))
    end
  })

  local function popup_text()
    if bat_state == nil then return end
    local text = "\n" .. bat_state.status
    if bat_state.time ~= "N/A" and bat_state.time ~= "00:00" then
      text = text .. "\n" .. bat_state.time .. "h/min left"
    end
    return markup.bold(markup(beautiful.dgrey, "battery")) .. "\n" .. text
  end

  hover_popup(battery.widget, popup_text)

end

return battery
