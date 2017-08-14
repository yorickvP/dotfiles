#!/bin/sh
#Spotify
spotify_status(){
	current_track=$(playerctl -p spotify metadata xesam:title)
	album=$(playerctl -p spotify metadata xesam:artist)
	echo -e $album" - " $current_track
}

spotify_control(){
	current_status=$(playerctl -p spotify status)
	if echo $current_status | grep -q "Playing"
		then echo "%{F#FF1DB954}%{A:i3-msg [class=Spotify] focus:}%{A}%{F-}  %{A:playerctl -p spotify previous:}  %{A}%{A:playerctl -p spotify play-pause:} $(spotify_status) %{A}%{A:playerctl -p spotify next:}  %{A}"
	elif echo $current_status | grep -q "Paused"
		then echo "%{F#FF1DB954}%{A:i3-msg [class=Spotify] focus:}%{A}%{F-}  %{A:playerctl -p spotify previous:}  %{A}%{A:playerctl -p spotify play-pause:}  $(spotify_status) %{A}%{A:playerctl -p spotify next:}  %{A}"
	fi
}

spotify_control
