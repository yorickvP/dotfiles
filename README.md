This repo contains code and specs for my personal infrastructure.

There is a centralized action runner tool 'ydeployer', which is accessible
from `nix develop` or using `direnv` (or using `nix run`).

# Computers
Configuration for all x86/arm systems is stored in [./nixos](). Specs are available in [./nixos/README.md]()

# bin
Assorted scripts in various states of deprecation.

# deployer
Deployment tool, written in typescript.

# emacs
.org files making up my daily editor configuration.

# esphome
Contains yaml configuration for esphome esp32 nodes.

# home-manager
nix configuration for my user profile on my desktop and laptops. Contains list of installed user-space programs.

# pkgs
Collection of nix files for packages that are not in nixpkgs, or patches for them.

# secrets
Secrets encrypted using agenix.

