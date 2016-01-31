#!/usr/bin/env bash
dmenu_args="-fn SourceCodePro:pixelsize=17 -nb "#002b36" -nf "#839496" -sb "#073642" -sf "#93a1a1" $@"

xclip -o | dmenu $dmenu_args -p Calculate: | xargs echo | bc | dmenu $dmenu_args -p "Answer:" | xclip -i
