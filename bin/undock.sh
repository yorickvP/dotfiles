#!/bin/sh
echo "undocking..." | systemd-cat -t dotfiles -p info
# if [ -e /sys/bus/pci/devices/0000\:04\:00.0/remove ]; then
#     echo 1 | sudo tee /sys/bus/pci/devices/0000\:04\:00.0/remove
#     echo "removed pci bridge"
#     sleep 2s
# else
#     echo "No pci device found, ignoring"
# fi
systemd-inhibit --what=handle-lid-switch sleep 45s & disown
swaymsg output '*' disable
swaymsg output eDP-1 enable
exit 0
