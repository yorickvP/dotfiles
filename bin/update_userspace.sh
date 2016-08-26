#!/usr/bin/env bash
nix-env -iA nixos.hosts.$(hostname -s)
