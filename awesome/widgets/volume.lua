local awful = require("awful")

local wibox = require("wibox")
-- widget library
local lain = require("lain")
local beautiful = require("beautiful")

local vol_icon = wibox.widget.imagebox()
local volumewidget = lain.widgets.alsa({
    settings = function()
        local level = volume_now.level .. "%"
        if volume_now.status == "off" then
            vol_icon:set_image(icon_dir .. "/spkr_02.png")
            level = markup(beautiful.lpink, level)
          else
            vol_icon:set_image(icon_dir .. "/spkr_01.png")
        end

        widget:set_markup(level)
    end
})
local volume = {
  widget = volumewidget,
  icon = vol_icon,
  mute = (function()
    os.execute(string.format("amixer set %s toggle", volumewidget.channel))
    volumewidget.update()
  end),
  down = (function()             
    os.execute(string.format("amixer set %s 1%%-", volumewidget.channel))
    volumewidget.update()
  end),
  up = (function()             
    os.execute(string.format("amixer set %s 1%%+", volumewidget.channel))
    volumewidget.update()
  end)
};
vol_icon:buttons(awful.util.table.join(awful.button({ }, 1, volume.mute)))
volumewidget:buttons(awful.util.table.join(
  awful.button({ }, 1, function ()
    awful.util.spawn("pavucontrol")
  end),
  awful.button({}, 4, volume.up),
  awful.button({}, 5, volume.down)
))

return volume
