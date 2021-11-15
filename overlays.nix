let sources = import ./nix/sources.nix;
in [
  (import ./fixups.nix)
  (import "${sources.nixpkgs-wayland}/overlay.nix")
  (import sources.nixpkgs-mozilla)
  (import sources.emacs-overlay)
  (import ./pkgs)
  (import ./pkgs/envs.nix)
  (import ./nixos/overlay.nix)
  (import ./overlay.nix)
]
