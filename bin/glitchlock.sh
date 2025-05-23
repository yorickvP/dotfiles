#!/bin/sh
set -euo pipefail
pngfile="/tmp/sclock.png"
bmpfile="/tmp/sclock.bmp"
glitchedfile="/tmp/sclock_g.bmp"
grim -t ppm $pngfile

# convert to bmp and pixelate
convert -scale 10% -scale 1000% $pngfile PPM:$bmpfile
rm $pngfile

# Glitch it with sox FROM: https://maryknize.com/blog/glitch_art_with_sox_imagemagick_and_vim/
sox -t ul -c 1 -r 48k $bmpfile -t ul $glitchedfile trim 0 100s : echo 0.9 0.9 15 0.9

# Rotate it by 90 degrees
convert $glitchedfile -rotate 90 PPM:$bmpfile

#Glitch it again and rotate it back
sox -t ul -c 1 -r 48k $bmpfile -t ul $glitchedfile trim 0 90s : echo 0.9 0.9 15 1
convert $glitchedfile -rotate -90 PPM:$glitchedfile
rm $bmpfile
# Add lock icon, pixelate and convert back to png
#  convert -gravity center -font "Hack-Bold-Nerd-Font-Complete-Mono" \
#      -pointsize 200 -draw "text 0,240 ''" -channel RGBA -fill '#bf616a' \
#      $glitchedfile $pngfile
# convert $glitchedfile $pngfile
convert $glitchedfile -crop 2560x1440+2560+0 PPM:/tmp/sclock_gr.bmp

swaylock -i DVI-D-1:$glitchedfile -i DP-3:/tmp/sclock_gr.bmp
#feh $glitchedfile
rm $glitchedfile /tmp/sclock_gr.bmp
