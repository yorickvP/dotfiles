#!/usr/bin/env bash
sudo nix-channel --update
nix-env -iA nixos.hosts.$(hostname -s)
