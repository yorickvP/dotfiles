---------------------------
-- Default awesome theme --
-- with a slightly different colour scheme
---------------------------

-- pale_white: #E0D0AA
-- bluegreen: #8DA893
-- base: #1D1E24
-- orange: #C18E44
-- brown: #493227

-- solarized
solar_base03 =   "#002b36" -- background
solar_base02 =   "#073642" -- bg hl
solar_base01 =   "#586e75" -- comments
solar_base00 =   "#657b83" -- base 0
solar_base0 =    "#839496" -- standard text
solar_base1 =    "#93a1a1" -- emph
solar_base2 =    "#eee8d5" -- wow
solar_base3 =    "#fdf6e3" -- very white
solar_yellow =   "#b58900"
solar_orange =   "#cb4b16"
solar_red =      "#dc322f"
solar_magenta =  "#d33682"
solar_violet =   "#6c71c4"
solar_blue =     "#268bd2"
solar_cyan =     "#2aa198"
solar_green =    "#859900"
transparent = "#00000000"
--

theme = {}

theme.font          = "Source Code Pro 9"

theme.bg_normal     = solar_base03 .. "d9"
theme.bg_focus      = transparent
theme.bg_urgent     = "#b0b0b0"
theme.bg_minimize   = transparent
theme.bg_systray    = "#202020aa"

theme.fg_normal     = solar_base0
theme.fg_focus      = solar_base1
theme.fg_urgent     = "#000000"
theme.fg_minimize   = solar_base01


theme.dgrey = solar_base0
theme.lpink = solar_orange
theme.dgreen = solar_green
theme.magenta = solar_magenta
theme.blue = solar_blue
theme.white = solar_base3
-- end temp, stolen

theme.border_width  = 2
theme.border_normal = solar_base03
theme.border_focus  = solar_base02
theme.border_marked = solar_red
-- theme.border_normal = theme.fg_normal
-- theme.border_normal = theme.bg_normal

theme.tasklist_bg_normal = transparent
awesome_path = "/home/yorick/.nix-profile/share/awesome/themes/default/"
-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:
--theme.taglist_bg_focus = "#ff0000"
--theme.bg_focus = theme.bg_normal
-- theme.taglist_fg_focus = "#C18E44"

-- Display the taglist squares
theme.taglist_squares_sel   = "/home/yorick/dotfiles/awesome/icons/squarefw.png"
theme.taglist_squares_unsel = "/home/yorick/dotfiles/awesome/icons/squarew.png"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = awesome_path .. "submenu.png"
theme.menu_height = 15
theme.menu_width  = 100

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = awesome_path .. "titlebar/close_normal.png"
theme.titlebar_close_button_focus  = awesome_path .. "titlebar/close_focus.png"

theme.titlebar_ontop_button_normal_inactive = awesome_path .. "titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = awesome_path .. "titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = awesome_path .. "titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active  = awesome_path .. "titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive = awesome_path .. "titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = awesome_path .. "titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = awesome_path .. "titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active  = awesome_path .. "titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive = awesome_path .. "titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = awesome_path .. "titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = awesome_path .. "titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active  = awesome_path .. "titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = awesome_path .. "titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = awesome_path .. "titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = awesome_path .. "titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active  = awesome_path .. "titlebar/maximized_focus_active.png"

theme.wallpaper = "/home/yorick/dotfiles/awesome/wallpaper.png"

-- You can use your own layout icons like this:
theme.layout_fairh = awesome_path .. "layouts/fairhw.png"
theme.layout_fairv = awesome_path .. "layouts/fairvw.png"
theme.layout_floating  = awesome_path .. "layouts/floatingw.png"
theme.layout_magnifier = awesome_path .. "layouts/magnifierw.png"
theme.layout_max = awesome_path .. "layouts/maxw.png"
theme.layout_fullscreen = awesome_path .. "layouts/fullscreenw.png"
theme.layout_tilebottom = awesome_path .. "layouts/tilebottomw.png"
theme.layout_tileleft   = awesome_path .. "layouts/tileleftw.png"
theme.layout_tile = awesome_path .. "layouts/tilew.png"
theme.layout_tiletop = awesome_path .. "layouts/tiletopw.png"
theme.layout_spiral  = awesome_path .. "layouts/spiralw.png"
theme.layout_dwindle = awesome_path .. "layouts/dwindlew.png"

theme.awesome_icon = "/home/yorick/dotfiles/awesome/icons/lambda.png"

-- Define the icon theme for application icons. If not set then the icons 
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

return theme
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
