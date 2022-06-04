#!/usr/bin/env bash
set -e

# Setup filename for the screenshot  
myfile="$(openssl rand -base64 9)_$(date +%y%m%d%H%M%S).webp"
  
webpath="https://pub.yori.cc/s/"
fileurl="$webpath$myfile"

# copy-paste
wl-copy <<< "$fileurl"
grimshot save window "$HOME/screenshot-tmp.ppm"
cwebp -preset picture -q 100 "$HOME/screenshot-tmp.ppm" -o "$HOME/public/s/$myfile"
rm "$HOME/screenshot-tmp.ppm"

cd ~
rsync -LavP --cvs-exclude public pub.yori.cc:
notify-send -t 3000 "saved $fileurl"
