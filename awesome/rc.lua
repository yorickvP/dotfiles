-- fix the package location
do
  confFolder = awesome.conffile:match("(/.+)/.+$")
  package.path = package.path .. ";" .. confFolder .. "/?.lua" .. ";" .. confFolder .. "/?/init.lua"
end

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- widget library
local vicious = require("vicious")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(confFolder .. "/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

icon_dir = confFolder .. "/icons/png"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    local tagNames = { "term", "web", "dev", "chat", "edu", "media", "misc", 8, 9 }
    local tagLayouts  = {   1,     2,     2,      2,     1,     1,       1, 1, 1 }
    for i,l in ipairs(tagLayouts) do
      tagLayouts[i] = layouts[l]
    end
    tags[s] = awful.tag(tagNames, s, tagLayouts)
end
-- }}}


-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

-- applications menu
myappsmenu = {
  { "firefox", "firefox" },
  { "luakit", "luakit" },
  { "htop", terminal .. " -e htop" },
  { "ranger", terminal .. " -e ranger" },
  { "chromium", "chromium" },
  { "quassel", "quassel" }
}
-- system
mysystemmenu = {
  { "lock", function () awful.util.spawn("xscreensaver-command -lock") end },
  { "Suspend", "systemctl suspend" },
  { "Restart", "systemctl reboot" },
  { "Shutdown", "systemctl poweroff" },
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "apps", myappsmenu },
                                    { "system", mysystemmenu },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })


awful.menu.menu_keys = { up    = { "k", "Up" },
                         down  = { "j", "Down" },
                         exec  = { "l", "Return", "Right" },
                         enter = { "Right" },
                         back  = { "h", "Left" },
                         close = { "q", "Escape" },
                       }

-- {{{ Wibox

-- stolen spacers
spacer = wibox.widget.textbox()
spacer:set_text(" ")
sqb_right = wibox.widget.textbox()
sqb_right:set_markup("<span color='" .. beautiful.dgrey .. "'>]</span>")
sqb_left = wibox.widget.textbox()
sqb_left:set_markup("<span color='" .. beautiful.dgrey .. "'>[</span>")


-- clock
clock_time = awful.widget.textclock('<span color="#d0d0d0">%H:%M</span>')
clock_day = awful.widget.textclock('<span color="#d0d0d0">%a %d/%m</span>')
clock_icon = wibox.widget.imagebox()
clock_icon:set_image(icon_dir .. "/clock.png")


-- google reader
-- google_reader_widget = wibox.widget.textbox()
-- google_reader_label = wibox.widget.textbox()
-- google_reader_label:set_markup("<span color='" .. beautiful.dgrey .. "'>RSS </span>")
-- do
--   google_reader_widget:set_markup("<span color='" .. beautiful.dgrey .. "'>loading</span>")
--   local greader_timer = timer({ timeout = 315 }) -- 5:15 minutes
--   local greader_info = "loading"
--   local loading_widget = false
--   function update_google_reader()
--     -- protect against loading multiple times
--     if loading_widget then
--       return
--     end
--     loading_widget = true
--     run_background("~/dotfiles/bin/reader_client.js totalunread", function (output)
--       loading_widget = false
--       greader_info = output:match( "(.-)%s*$") -- removed trailing whitespace
--       google_reader_widget:set_markup("<span color='" .. beautiful.magenta .. "'>".. greader_info .."</span>")
--     end)
--   end
--   greader_timer:connect_signal("timeout", update_google_reader)
--   greader_timer:start()
--   update_google_reader()

--   -- tooltip stuff
--   local greader_tooltip
--   local greader_info_details = "loading"

--   function remove_greader()
--       if greader_tooltip~= nil then
--           naughty.destroy(greader_tooltip)
--           greader_tooltip = nil
--       end
--   end

--   local loading_tooltip = false
--   function update_greader_tooltip()
--     if loading_tooltip then
--       return
--     end
--     loading_tooltip = true
--     run_background("~/dotfiles/bin/reader_client.js unreadlist", function (output)
--       loading_tooltip = false
--       greader_info_details = string.gsub(output, "%$(%w+)", "%1")
--       greader_info_details = greader_info_details:match( "(.-)%s*$") -- removed trailing whitespace
--     end)
--   end

--   function add_greader()
--       remove_greader()
--       greader_tooltip = naughty.notify({
--        title = "<span color='" .. beautiful.dgrey .. "'>google reader ("..greader_info.." new)</span>",
--        text = greader_info_details,
--        timeout = 0,
--        screen = mouse.screen
--       })
--   end

--   update_greader_tooltip()
--   greader_timer:connect_signal("timeout", update_greader_tooltip)

--   google_reader_widget:connect_signal("mouse::enter", add_greader)
--   google_reader_widget:connect_signal("mouse::leave", remove_greader)
--   google_reader_widget:buttons(awful.util.table.join(
--       awful.button({ }, 1, function () awful.util.spawn("firefox reader.google.com", false) end),
--       awful.button({ }, 2, function ()
--         update_greader_tooltip()
--         update_google_reader()
--       end)))

-- end

-- battery
battery_widget = wibox.widget.textbox()
battery_icon = wibox.widget.imagebox()
battery_icon:set_image(icon_dir .. "/bat_empty_01.png") -- todo: change based on fullness
do
  local icon_full = icon_dir .. "/bat_full_01.png"
  local icon_low = icon_dir .. "/bat_low_01.png"
  local icon_empty = icon_dir .. "/bat_empty_01.png"
  local show_Naughtyfication = true
  local arguments = nil

  if show_Naughtyfication then
    local battery = nil

    local battery_state = {
         ["⌁"] = "unknown",
         ["↯"] = "charged",
         ["+"] = "charging",
         ["-"] = "discharging"
     }

    function remove_battery()
      if battery ~= nil then
        naughty.destroy(battery)
        battery = nil
      end
    end
    function add_battery()
        if arguments == nil then
          return
        end
        remove_battery()
        local text = "\n" .. battery_state[arguments[1]]
        if arguments[3] ~= "N/A" then
          text = text .. "\n" .. arguments[3] .. "h/min remaining"
        end
        battery = naughty.notify({
            title = "<span color='" .. beautiful.dgrey .. "'>battery</span>",
            text = text,
            timeout = 0,
            screen = mouse.screen,
            --ontop = true,
        })
    end

    battery_widget:connect_signal("mouse::enter", add_battery)
    battery_widget:connect_signal("mouse::leave", remove_battery)

  end

  vicious.register(battery_widget, vicious.widgets.bat, function (widget, args)
    arguments = args

    if args[2] < 10 then
        naughty.notify({ title="<span color='" .. beautiful.dgrey .. "'>Low Battery Level!</span>\n", 
        text="" .. args[3] .. " min remaining",
        timeout=35 })
        battery_icon:set_image(icon_empty)
        return "<span color='" .. beautiful.lpink .. "'>" .. args[2] .. args[1] .. "</span>"
    elseif args[2] < 30 then
        battery_icon:set_image(icon_low)
        return "<span color='" .. beautiful.lpink .. "'>" .. args[2] .. args[1] .. "</span>"
    else
        battery_icon:set_image(icon_full)
        return "<span color='" .. beautiful.dgreen .. "'>" .. args[2] .. args[1] .. "</span>"
    end
  end, 96, "BAT0")
end
-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(sqb_left)
    left_layout:add(mytaglist[s])
    left_layout:add(sqb_right)
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then
      right_layout:add(sqb_left)
      right_layout:add(wibox.widget.systray())
      right_layout:add(sqb_right)
      right_layout:add(spacer)
    end
    --right_layout:add(sqb_left)
    -- right_layout:add(google_reader_label)
    -- right_layout:add(google_reader_widget)
    --right_layout:add(sqb_right)
    --right_layout:add(spacer)
    right_layout:add(sqb_left)
    right_layout:add(battery_icon)
    right_layout:add(battery_widget)
    right_layout:add(sqb_right)
    right_layout:add(spacer)
    right_layout:add(sqb_left)
    right_layout:add(clock_icon)
    right_layout:add(clock_day)
    right_layout:add(spacer)
    right_layout:add(clock_time)
    right_layout:add(sqb_right)
    right_layout:add(spacer)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    -- dmenu launcher
    awful.key({ modkey },            "e",     function () awful.util.spawn("/home/yorick/dotfiles/bin/dlaunch.sh") end),
    awful.key({ modkey },            "=",     function () awful.util.spawn("/home/yorick/dotfiles/bin/dcalc.sh") end),
    awful.key({ modkey },            "z",     function () awful.util.spawn("/home/yorick/dotfiles/bin/dwinpick.sh") end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- locking
    awful.key({ modkey, "Control", "Shift" }, "l", function () awful.util.spawn("xscreensaver-command -lock") end),
    -- brightness adjustment
    awful.key({ }, "XF86MonBrightnessDown", function() awful.util.spawn("/home/yorick/dotfiles/bin/brightne.sh down") end),
    awful.key({ }, "XF86MonBrightnessUp", function() awful.util.spawn("/home/yorick/dotfiles/bin/brightne.sh up") end),
    awful.key({ }, "XF86AudioMute", function() awful.util.spawn("/home/yorick/dotfiles/bin/mute_toggle.sh") end),
    awful.key({ }, "XF86AudioLowerVolume", function() awful.util.spawn("/home/yorick/dotfiles/bin/vol_down.sh") end),
    awful.key({ }, "XF86AudioRaiseVolume", function() awful.util.spawn("/home/yorick/dotfiles/bin/vol_up.sh") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber))
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local title = awful.titlebar.widget.titlewidget(c)
        title:buttons(awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(title)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
