#!/bin/bash
dmenu_args="-fn -*-termsyn-medium-*-*-*-12-*-*-*-*-*-*-* -nb #1D1E24 -nf #8DA893 -sb #1D1E24 -sf #C18E44 $@"
winlist=`echo "local q = \"\"; for i,c in ipairs(client.get()) do q=q..c.name..\"\\n\" end; return q" | awesome-client | tail -c +12 | head -c -2`
choice=`echo "$winlist" | dmenu -i -l 7 $dmenu_args`
if [ -n "$choice" ]; then
	wmctrl -a "$choice"
fi
