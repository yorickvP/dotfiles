#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nitrogen xorg.xrandr
xrandr \
 --output VGA-1 --off \
 --output eDP-1 --off \
 --output LVDS-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
 --output DP-3 --off \
 --output DP-2 --off \
 --output DP-1 --off
nitrogen --restore
