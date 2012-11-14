#!/bin/bash
# brightne.sh

# changes my backlight brightness, for use with nvidiabl
# possibly the ugliest bash script ever

# Requires /sys/class/backlight/nvidia_backlight/

E_NOARGS=75

backlight_path=/sys/class/backlight/nvidia_backlight

usage() {
  echo "Usage: brightne.sh [set|fix|up|down] arg between 0 and 1024"
}

get_raw_maximum() {
	return `cat $backlight_path/max_brightness`
}

get_raw_current() {
	return `cat $backlight_path/brightness`
}

set_raw() {
	echo $1 > $backlight_path/brightness
}

# from 0-1024 to 0-max
scale_to_bl() {
	get_raw_maximum
	max=$?
	echo "$max * $1 / 1024" | bc
}

# from 0-max to 0-1024
scale_from_bl() {
	get_raw_maximum
	max=$?
	echo "1024 * $1 / $max" | bc
}

off() {
	set_raw 0;
}

max() {
	get_raw_maximum
	raw_current=$?
	set_raw $raw_current
}

set_bl() {
	set_raw $(scale_to_bl $1)
}

get() {
	get_raw_current
	echo $(scale_from_bl $?)
}

fix() {
	get_raw_current
	set_raw $?
}

up() {
	local addvalue=$1
	if [ -z $1 ]
		then
		addvalue=10
	fi
	set_bl $(echo "$(get) + $addvalue" | bc)
}

down() {
	local addvalue=$1
	if [ -z $1 ]
		then
		addvalue=10
	fi
	set_bl $(echo "$(get) - $addvalue" | bc)
}

if [ -z "$1" ]
then
  usage
  exit $E_NOARGS
fi

case $1 in
	"up"    ) up $2;;
	"set"    ) set_bl $2;;
	"down"    ) down $2;;
	"fix"    ) fix;;
	"get"    ) get;;
	"off"	) off ;;
	"max"	) max ;;
    *       ) usage;;
esac

exit 0