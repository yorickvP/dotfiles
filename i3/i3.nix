{writeTextDir, writeScript, lib,
rofi, xss-lock, nitrogen, compton-git, i3status, i3-gaps,
i3lock-color, xset, alsaUtils, light, screenshot_public, xorg, libinput-gestures,
haskellPackages, polybar, rofi-pass, xsettingsd,
with_lock ? true, compton_name ? "default"}:

let
  kill-and-then = kill: thn:
''exec_always --no-startup-id "pkill ${kill}; while pgrep -x ${kill} >/dev/null; do sleep 1; done; ${thn}"'';
  kill-and-restart = pkg: as:
with lib; let
  name = head (splitString " " as);
  args = concatStringsSep " " (tail (splitString " " as));
in kill-and-then name "exec ${pkg}/bin/${name} ${args}";
locker = writeScript "dlock.sh" ''
#!/bin/sh
revert() {
  ${xset}/bin/xset dpms 0 0 0
}
trap revert SIGHUP SIGINT SIGTERM
${xset}/bin/xset +dpms dpms 5 5 5
${i3lock-color}/bin/i3lock-color -B 10 -r -n -e
revert
'';

in

writeTextDir "i3-config" (''
# i3 config file (v4)
# Please see http://i3wm.org/docs/userguide.html for a complete reference!

set $mod Mod4

gaps inner 5
# gaps outer 5

font pango:Source Code Pro 10

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
bindsym $mod+Shift+1 move container to workspace number 1
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

bindsym $mod+ctrl+l exec --no-startup-id loginctl lock-session

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


exec_always --no-startup-id ${nitrogen}/bin/nitrogen --restore
${kill-and-restart compton-git "compton --config /home/yorick/dotfiles/x/compton_${compton_name}.conf"}
'' + (lib.optionalString with_lock ''

${kill-and-then "polybar" "PATH=${polybar}/bin:$PATH /home/yorick/dotfiles/i3/polybar.sh"}
${kill-and-restart xss-lock "xss-lock -l -- ${locker}"}
${kill-and-restart libinput-gestures "libinput-gestures"}
${kill-and-restart haskellPackages.arbtt "arbtt-capture"}
${kill-and-restart xsettingsd "xsettingsd"}
'') + ''

bindsym XF86MonBrightnessUp exec ${light}/bin/light -A 5
bindsym XF86MonBrightnessDown exec ${light}/bin/light -U 5
bindsym ctrl+XF86MonBrightnessUp exec ${light}/bin/light -A 1
bindsym ctrl+XF86MonBrightnessDown exec ${light}/bin/light -U 1
bindsym XF86AudioLowerVolume exec ${alsaUtils}/bin/amixer set Master 1%-
bindsym XF86AudioRaiseVolume exec ${alsaUtils}/bin/amixer set Master 1%+
bindsym XF86AudioMute exec ${alsaUtils}/bin/amixer set Master toggle
bindsym $mod+Shift+s exec --no-startup-id ${screenshot_public}/bin/screenshot_public
bindsym Print exec --no-startup-id ${screenshot_public}/bin/screenshot_public
bindsym $mod+p exec --no-startup-id ${rofi-pass}/bin/rofi-pass
bindsym $mod+Shift+t exec --no-startup-id /home/yorick/dotfiles/bin/toggle_solarized.sh
workspace_auto_back_and_forth yes

hide_edge_borders smart
for_window [class="URxvt"] border pixel 2
new_window pixel 2
'')
