#!/bin/sh
# this script checks if the system is docked with the lid closed
# and if so, sets the correct DPI, disables the laptop screen, sets the DP-3 monitor as primary
# and loads the nvidia config for vsync options and sets the dithering depth to 8
if [ `cat /sys/devices/platform/hp-wmi/dock` -eq 1 ] # && [[ `cat /proc/acpi/button/lid/LID/state` == *closed* ]]
then
	echo "Using docked configuration with 27\" IPS screen"
	#xrandr --output DP-3 --primary --preferred --output LVDS-0 --left-of DP-6 --off --dpi 109/DP-3
	xrandr --output DP-3 --primary --preferred --output LVDS-0 --off --dpi 109/DP-3
	nvidia-settings -a "0/XVideoSyncToDisplayID=DP-3"
	echo "Xft.dpi: 109" | xrdb -merge
else
	echo "Using laptop-only configuration"
	xrandr --size 1920x1080 --output LVDS-0 --mode 1920x1080 --primary --preferred --rotate normal --pos 0x0 --output VGA-0 --off --output DP-3 --off --output DP-6 --off --dpi 146/LVDS-0
	nvidia-settings -l -a "0/XVideoSyncToDisplayID=LVDS-0"
	echo "Xft.dpi: 146" | xrdb -merge
fi
feh --bg-fill ~/wp_roll/1633_layinginthegrass_1920x1080.jpg
