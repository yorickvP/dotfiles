#!/bin/bash
# Credit to Roland Latour
# http://www.freak-search.com/en/thread/4707111/q_volume_control,_xfce

# lower volume by 1%

# Find default sink
sink=$(pacmd info|grep "Default sink name"|awk '{print $4}')

# Now we need to find volume of default sink
# get line# of start of definition for default sink (plus 1, actually)
let line=$(pacmd list-sinks|grep -n $sink|sed '{s/://}'|awk '{print $1}')

# index down a bit for volume line
let line=($line + 6)
volume=$(pacmd list-sinks|awk 'NR=="'"$line"'"{print $3}'|sed '{s/%//}')

# pacmd returns volume as %, but demands setting as range: 0-65535
let volume=($volume - 1)
let volume=($volume * 65536);let volume=($volume / 100)
[[ $volume -lt 0 ]] && let volume=0
pacmd set-sink-volume $sink $volume > /dev/null 2>&1
volnoti-show $(((volume * 100) / 65536))
