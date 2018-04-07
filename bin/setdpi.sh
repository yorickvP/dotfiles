DPI=$1
echo "setting dpi: $DPI"
sed -i "s#Xft/DPI [0-9]*#Xft/DPI $((DPI*1024))#" ~/.xsettingsd
echo "Xft.dpi: $DPI" | xrdb -merge
echo "*dpi: $DPI" | xrdb -merge
xrandr --dpi $DPI
pkill -HUP xsettingsd
pkill -USR1 polybar
