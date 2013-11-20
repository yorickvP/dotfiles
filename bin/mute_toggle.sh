#!/bin/bash

# Credit to Roland Latour
# http://www.freak-search.com/en/thread/4707111/q_volume_control,_xfce

# Find default sink

mute_cmd=$(amixer set Master toggle | egrep 'Playback.*?\[o' | head -n 1)
mute=$(echo "$mute_cmd" | egrep -o '\[o.+\]')
volume=$(echo "$mute_cmd" | sed '{s/://}' | awk '{print $4}')
let volume=($volume * 100 / 65536)
if [[ "$mute" == "[on]" ]]; then
	# show the volume
	volnoti-show $volume
fi
[[ "$mute" == "[off]" ]] && volnoti-show -m
