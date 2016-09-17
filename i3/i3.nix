{writeTextDir, writeScript, lib,
rofi, xautolock, nitrogen, compton-git, i3status, i3-gaps
, i3lock-fancy, xset, alsaUtils, brightness, screenshot_public,
with_lock ? true}:

let
locker = writeScript "dlock.sh" ''
#!/bin/sh
revert() {
  ${xset}/bin/xset dpms 0 0 0
}
trap revert SIGHUP SIGINT SIGTERM
${xset}/bin/xset +dpms dpms 5 5 5
${i3lock-fancy}/bin/i3lock-fancy
revert
'';

in

writeTextDir "i3-config" (''
# i3 config file (v4)
# Please see http://i3wm.org/docs/userguide.html for a complete reference!

set $mod Mod4

gaps inner 5
gaps outer 5

font pango:Source Code Pro 9

# Before i3 v4.8, we used to recommend this one as the default:
# font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
# The font above is very space-efficient, that is, it looks good, sharp and
# clear in small sizes. However, its unicode glyph coverage is limited, the old
# X core fonts rendering does not support right-to-left and this being a bitmap
# font, it doesn’t scale on retina/hidpi displays.

# Use Mouse+$mod to drag floating windows to their wanted position
floating_modifier $mod

# start a terminal
bindsym $mod+Return exec i3-sensible-terminal

# kill focused window
bindsym $mod+Shift+c kill

# start dmenu (a program launcher)
bindsym $mod+e exec --no-startup-id ${rofi}/bin/rofi -fuzzy -show drun
bindsym $mod+z exec --no-startup-id ${rofi}/bin/rofi -fuzzy -show window

# change focus
bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right

# alternatively, you can use the cursor keys:
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# move focused window
bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right

# alternatively, you can use the cursor keys:
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# split in horizontal orientation
bindsym $mod+h split h

# split in vertical orientation
bindsym $mod+v split v

# enter fullscreen mode for the focused container
bindsym $mod+f fullscreen toggle

# change container layout (stacked, tabbed, toggle split)
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+d layout toggle split

# toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# change focus between tiling / floating windows
bindsym $mod+space focus mode_toggle

# focus the parent container
bindsym $mod+a focus parent

# focus the child container
#bindsym $mod+d focus child

# switch to workspace
bindsym $mod+1 workspace 1
bindsym $mod+2 workspace 2
bindsym $mod+3 workspace 3
bindsym $mod+4 workspace 4
bindsym $mod+5 workspace 5
bindsym $mod+6 workspace 6
bindsym $mod+7 workspace 7
bindsym $mod+8 workspace 8
bindsym $mod+9 workspace 9
bindsym $mod+0 workspace 10

# move focused container to workspace
bindsym $mod+Shift+1 move container to workspace 1
bindsym $mod+Shift+2 move container to workspace 2
bindsym $mod+Shift+3 move container to workspace 3
bindsym $mod+Shift+4 move container to workspace 4
bindsym $mod+Shift+5 move container to workspace 5
bindsym $mod+Shift+6 move container to workspace 6
bindsym $mod+Shift+7 move container to workspace 7
bindsym $mod+Shift+8 move container to workspace 8
bindsym $mod+Shift+9 move container to workspace 9
bindsym $mod+Shift+0 move container to workspace 10

bindsym $mod+ctrl+r reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"

bindsym $mod+ctrl+l exec --no-startup-id ${xautolock}/bin/xautolock -locknow

# resize window (you can also use the mouse for that)
mode "resize" {
        # These bindings trigger as soon as you enter the resize mode

        # Pressing left will shrink the window’s width.
        # Pressing right will grow the window’s width.
        # Pressing up will shrink the window’s height.
        # Pressing down will grow the window’s height.
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt

        # same bindings, but for the arrow keys
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt

        # back to normal: Enter or Escape
        bindsym Return mode "default"
        bindsym Escape mode "default"
}

bindsym $mod+r mode "resize"
bindsym $mod+Escape workspace back_and_forth

# Start i3bar to display a workspace bar (plus the system information i3status
# finds out, if available)
bar {
        i3bar_command ${i3-gaps}/bin/i3bar -t
        status_command ${i3status}/bin/i3status
        colors {
                background #002b36d9
                statusline #839496
        }
}

exec --no-startup-id ${nitrogen}/bin/nitrogen --restore
exec --no-startup-id ${compton-git}/bin/compton --config /home/yorick/dotfiles/x/compton.conf

'' + (lib.optionalString with_lock ''

exec --no-startup-id ${xautolock}/bin/xautolock -time 15 -locker ${locker} -lockaftersleep

'') + ''

bindsym XF86MonBrightnessUp exec ${brightness}/bin/brightness up 50
bindsym XF86MonBrightnessDown exec ${brightness}/bin/brightness down 50
bindsym XF86AudioLowerVolume exec ${alsaUtils}/bin/amixer set Master 1%-
bindsym XF86AudioRaiseVolume exec ${alsaUtils}/bin/amixer set Master 1%+
bindsym XF86AudioMute exec ${alsaUtils}/bin/amixer set Master toggle
bindsym $mod+Shift+s exec --no-startup-id ${screenshot_public}/bin/screenshot_public


'')
