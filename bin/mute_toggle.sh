#!/bin/bash

# Credit to Roland Latour
# http://www.freak-search.com/en/thread/4707111/q_volume_control,_xfce

# Find default sink
sink=$(pacmd info|grep "Default sink name"|awk '{print $4}')

# Now we need to get mute status of default sink
# get line# of start of definition for default sink (plus 1, actually)

let line=$(pacmd list-sinks|grep -n $sink|sed '{s/://}'|awk '{print $1}')
# add 12 for "muted" line

let line=($line + 10)

# extract mute status from that line
mute=$(pacmd list-sinks|awk 'NR==i"'"$line"'"{print $2}')

if [[ "$mute" == "yes" ]]; then
	# show the volume
	# Now we need to find volume of default sink
	# get line# of start of definition for default sink (plus 1, actually)
	let line=$(pacmd list-sinks|grep -n $sink|sed '{s/://}'|awk '{print $1}')

	# index down a bit for volume line
	let line=($line + 6)
	volume=$(pacmd list-sinks|awk 'NR=="'"$line"'"{print $3}'|sed '{s/%//}')


	pacmd set-sink-mute "$sink" 0 > /dev/null 2>&1
	volnoti-show $volume
fi
[[ "$mute" == "no" ]] && pacmd set-sink-mute "$sink" 1 > /dev/null 2>&1 && volnoti-show -m
