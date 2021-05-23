#!/bin/sh
mosquitto_pub -h frumar.local -u iot -P asdf -t "yorick/home/office/sunplate" -m $1
