#!/bin/sh
if swaymsg -t get_outputs | grep 36H03689019; then
    echo should dock
    swaymsg 'output "Unknown  0x00000000" enable position 0 0 mode 2560x1440@59.951Hz bg ~/wp/"001 - Aalborg.jpg" stretch, output "BenQ Corporation BenQ GW2765 36H03689019" enable position 2560 0 mode 2560x1440@59.951Hz bg ~/wp/"002 - Alkali.jpg" stretch, output eDP-1 disable'
    ~/dotfiles/bin/setdpi.sh 109
    systemctl --user restart waybar
elif swaymsg -t get_outputs | grep GH85D7CK1CXL; then
    echo should lumi
    BG='bg /home/yorick/Lumiguide-Generic/"01. General/06. Branding/Logo/New Logo & Stationary 2019/Lumiguide logo"/lumiguide-logo-01.png fit '#fdf6e3''
    #BG='bg /home/yorick/Lumiguide-Generic/"01. General/06. Branding/Logo/New Logo & Stationary 2019/Lumiguide logo"/lumiguide-logo-02.png fit '#263238''
    swaymsg 'output eDP-1 enable position 0 1440 scale 2, output "Dell Inc. DELL U2715H GH85D7CK17FL" enable position 2560 0 '$BG', output "Dell Inc. DELL U2715H GH85D7CK1CXL" enable position 0 0 '$BG
    ~/dotfiles/bin/setdpi.sh 109
    systemctl --user restart waybar
 else
    echo should undock
    systemd-inhibit --what=handle-lid-switch sleep 45s & disown
    swaymsg 'output * disable, output eDP-1 enable scale 2 position 0 0'
    ~/dotfiles/bin/setdpi.sh 192
    systemctl --user restart waybar
fi
