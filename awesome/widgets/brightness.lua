local awful = require("awful")

local wibox = require("wibox")
-- widget library
local lain = require("lain")

local script = "/home/yorick/dotfiles/bin/brightne.sh"
local bness_widget = lain.widgets.base({
  cmd = script .. " get",
  settings = (function()
    widget:set_text(output)
  end),
  timeout = 20
})
local brightness = {
  icon = wibox.widget.imagebox(),
  widget = bness_widget,
  down = (function()
    os.execute(script .. " down")
    bness_widget.update()
    end),
  up = (function()
    os.execute(script .. " up")
    bness_widget.update()
    end),
  fix = (function()
    os.execute(script .. " fix")
    bness_widget.update()
    end),
}
brightness.widget:buttons(awful.util.table.join(
  awful.button({}, 1, brightness.fix),
  awful.button({}, 4, brightness.up),
  awful.button({}, 5, brightness.down)
))
brightness.icon:set_image(icon_dir .. "/half.png")

return brightness
