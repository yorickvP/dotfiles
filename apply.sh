#!/usr/bin/env bash
set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )"
# todo: fetch
system=$(nix eval --raw .#stdenv.system)
set -x
nixos-rebuild build --flake .#
nix build .#yorick-home --no-link
nix run .#update-home
nixos-rebuild switch --flake .# --target-host root@localhost
rm -f result
