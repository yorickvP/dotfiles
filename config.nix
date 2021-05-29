let sources = import ./nix/sources.nix;
in
  {
    allowUnfree = true;
    overlays = [
      (import sources.nixpkgs-wayland)
      (import sources.nixpkgs-mozilla)
      (import sources.emacs-overlay)
      (import ./nixos/overlay.nix)
      (import ./nix/.config/nixpkgs/overlays/01-backports.nix)
      (import ./nix/.config/nixpkgs/overlays/02-extrapkgs.nix)
      (import ./nix/.config/nixpkgs/overlays/03-customizations.nix)
      (import ./nix/.config/nixpkgs/overlays/04-combine.nix)
      (import ./nix/.config/nixpkgs/overlays/05-envs.nix)
    ];
  }
