#!/usr/bin/env nix-shell
#!nix-shell -i bash -p stow
stow -d `dirname $0` nix git x pentadactyl
