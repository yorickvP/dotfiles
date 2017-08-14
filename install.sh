#!/usr/bin/env bash
#!nix-shell -i bash -p stow
$(nix-build '<nixpkgs>' -A stow --no-out-link)/bin/stow -d `dirname $0` -t ~ nix git x pentadactyl gtk gpg mutt misc bash stow
nix-build -A $(hostname -s)
