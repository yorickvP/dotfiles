#!/bin/sh

for m in $(xrandr --listactivemonitors | grep ": +" | cut -d " " -f 3 -); do
    MONITOR=$(echo $m | tr -d +*) polybar -c ~/dotfiles/i3/polybar $(hostname)_$(echo $m | grep -q "*" && echo primary || echo other) &
done
