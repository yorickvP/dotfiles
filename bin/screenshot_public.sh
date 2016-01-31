#!/bin/sh  
  
# Setup filename for the screenshot  
myfile=$(date +%Y%m%d%H%M%S).png  
  
webpath='https://pub.yori.cc/screen/' 
fileurl=$webpath$myfile  
  
# see: http://code.google.com/p/xmonad/issues/detail?id=476  
sleep 0.2  
  
scrot $myfile -e 'mv $f ~/public/screen/' -s  
  
# copy-paste
echo $fileurl | xclip -selection c  
cd ~
rsync -LavP --cvs-exclude public pub.yori.cc:
