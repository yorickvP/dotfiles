let sources = import /home/yorick/dotfiles/nix/sources.nix;
in import sources.nixpkgs (import ./config.nix)
