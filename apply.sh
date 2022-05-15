#!/usr/bin/env bash
set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )"
# todo: fetch
system=$(nix eval --raw .#stdenv.system)
set -x
nixos-rebuild build --flake .#
nix build .#yorick-home --no-link
home-manager switch --flake .#$system
nixos-rebuild switch --flake .# --target-host root@localhost
rm -f result
set +x
echo "Updating nix-index cache"
(
  filename="index-x86_64-$(uname | tr A-Z a-z)"
  mkdir -p ~/.cache/nix-index
  cd ~/.cache/nix-index
  # -N will only download a new version if there is an update.
  wget -q -N https://github.com/Mic92/nix-index-database/releases/latest/download/$filename
  ln -f $filename files
)
