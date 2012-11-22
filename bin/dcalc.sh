#!/bin/bash
dmenu_args="-fn -*-termsyn-medium-*-*-*-12-*-*-*-*-*-*-* -nb #1D1E24 -nf #8DA893 -sb #1D1E24 -sf #C18E44 $@"

xsel -o | dmenu $dmenu_args -p Calculate: | xargs echo | calc -p | dmenu $dmenu_args -p "Answer:" | xsel -i
