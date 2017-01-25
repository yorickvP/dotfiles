#!/usr/bin/env nix-shell
#!nix-shell -i bash -p stow
stow -d `dirname $0` -t ~ nix git x pentadactyl i3 gtk gpg mutt misc
nix-build -A $(hostname -s)
