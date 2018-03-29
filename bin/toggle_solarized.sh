#!/usr/bin/env bash
DIR=~/dotfiles/x/solarized
COL=${1:-$(readlink $DIR/alternate)}
if [ $COL == "dark" ]; then
    ROFI_THEME=solarized_alternate
    ALTERNATE=light;
fi
if [ $COL == "light" ]; then
    ALTERNATE=dark;
    ROFI_THEME=Arc
fi

echo "changing to solarized_$COL"
# rofi
sed -i "s/theme: .*;/theme: \"$ROFI_THEME\";/" ~/dotfiles/rofi/.config/rofi/config.rasi
# xrdb
ln -fs $ALTERNATE $DIR/alternate
ln -fs $COL $DIR/actual
xrdb ~/dotfiles/x/.Xdefaults
# urxvt
RECOLOR=$(xrdb -query | tr -d ' \t' | sed -n '
s/.*background:/\x1b]11;/p
s/.*foreground:/\x1b]10;/p
s/.*borderColor:/\x1b]708;/p
s/.*color\([0-9][^:]*\):/\x1b]4;\1;/p
' | tr \\n \\a)
for i in /dev/pts/*; do
    echo -n $RECOLOR > $i
done
#polybar
pkill -USR1 polybar
#emacs
emacsclient -e "(load-theme 'solarized-$COL)"
