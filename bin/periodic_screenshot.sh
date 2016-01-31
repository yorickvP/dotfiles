#!/bin/zsh

format="%Y-%m-%d_%H-%M_$(hostname).png"
exec="mv \$f $HOME/periodic_screenshot/"

if [[ $(pidof X) -gt 0 ]]; then
  DISPLAY=:0.0 xset -b
  DISPLAY=:0.0 scrot -m $format -q 10 -e "$exec"
  DISPLAY=:0.0 xset b
fi

