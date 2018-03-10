#!/usr/bin/env bash
set -e
nix build --no-link -f '<nixpkgs>' hosts.$(hostname -s)
nix-env -iA nixos.hosts.$(hostname -s)
