#!/bin/sh
#Spotify
exec playerctl metadata -f '{{emoji(status)}} {{xesam:artist}} - {{xesam:title}}' -F
