#!/usr/bin/env bash
#!nix-shell -i bash -p stow
set -e
$(nix-build '<nixpkgs>' -A stow --no-out-link)/bin/stow -d `dirname $0` -t ~ nix x gtk gpg mutt stow rofi
nix build -f. $(hostname -s)
