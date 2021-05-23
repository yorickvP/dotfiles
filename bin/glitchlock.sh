#!/bin/sh
set -euo pipefail
pngfile="/tmp/sclock.png"
bmpfile="/tmp/sclock.bmp"
glitchedfile="/tmp/sclock_g.bmp"
grim -t ppm $pngfile

# convert to bmp and pixelate
convert -scale 10% -scale 1000% $pngfile $bmpfile
rm $pngfile

# Glitch it with sox FROM: https://maryknize.com/blog/glitch_art_with_sox_imagemagick_and_vim/
sox -t ul -c 1 -r 48k $bmpfile -t ul $glitchedfile trim 0 100s : echo 0.9 0.9 15 0.9

# Rotate it by 90 degrees
convert -rotate 90 $glitchedfile $bmpfile

#Glitch it again and rotate it back
sox -t ul -c 1 -r 48k $bmpfile -t ul $glitchedfile trim 0 90s : echo 0.9 0.9 15 1
convert -rotate -90 $glitchedfile $glitchedfile
rm $bmpfile
# Add lock icon, pixelate and convert back to png
#  convert -gravity center -font "Hack-Bold-Nerd-Font-Complete-Mono" \
#      -pointsize 200 -draw "text 0,240 ''" -channel RGBA -fill '#bf616a' \
#      $glitchedfile $pngfile
# convert $glitchedfile $pngfile

swaylock -i $glitchedfile
#feh $pngfile
rm $glitchedfile
