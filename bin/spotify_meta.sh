#!/bin/sh
#Spotify
exec playerctl metadata -f '{{emoji(playerName)}} {{emoji(status)}} {{xesam:artist}} - {{xesam:title}}' -F
