#!/usr/bin/sh
# this script checks if the system is docked with the lid closed
# and if so, sets the correct DPI, disables the laptop screen, sets the DP-3 monitor as primary
# and loads the nvidia config for vsync options and sets the dithering depth to 8
if [ `cat /sys/devices/platform/hp-wmi/dock` -eq 1 ] && [[ `cat /proc/acpi/button/lid/LID/state` == *closed* ]]
then
	echo "Using docked configuration with 27\" IPS screen and VGA-screen"
	xrandr --output LVDS-0 --off --output DP-3 --primary --output VGA-0 --left-of DP-3 --dpi 108.79/DP-3
	nvidia-settings -l -a "[dpy:DP-3]/DitheringDepth=2" -a "0/XVideoSyncToDisplay=1048576"
	echo "Xft.dpi: 108.79" | xrdb -merge
else
	echo "Using laptop-only configuration"
	xrandr --output LVDS-0 --mode 1920x1080 --primary --rotate normal --pos 0x0 --output VGA-0 --off --output DP-3 --off --dpi 146.86/LVDS-0
	nvidia-settings -l
	echo "Xft.dpi: 146.86" | xrdb -merge
fi
