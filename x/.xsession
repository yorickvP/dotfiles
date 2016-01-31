#!/bin/sh
# compose led - not working
# export _XKB_OPTIONS_ENABLE=1
# export _XKB_COMP_LED=1

feh --bg-fill ~/dotfiles/awesome/wallpaper.jpg
#source /etc/profile.d/infinality-settings.sh
~/dotfiles/bin/docked.sh
#syndaemon -t -k -i 1 -d &
# compositing, start after awesome
#(sleep 2s; compton --config ~/dotfiles/misc/compton.conf -b) &
exec awesome -c ~/dotfiles/awesome/rc.lua

