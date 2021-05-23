#!/usr/bin/env bash
set -e

# Setup filename for the screenshot  
myfile="$(openssl rand -base64 9)_$(date +%y%m%d%H%M%S).png"
  
webpath="https://pub.yori.cc/s/"
fileurl="$webpath$myfile"
  
grim -g "$(slurp)" "$HOME/public/s/$myfile"

# copy-paste
wl-copy <<< "$fileurl"
cd ~
rsync -LavP --cvs-exclude public pub.yori.cc:
