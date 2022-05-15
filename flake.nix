{
  description = "Yoricks dotfiles";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-mozilla.url = "github:mozilla/nixpkgs-mozilla";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-21.05";
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ nixpkgs, home-manager, nixpkgs-mozilla, emacs-overlay, nixpkgs-wayland, nixpkgs-stable, nixos-hardware, self, ... }: {
    overlays.default = [
      nixpkgs-wayland.overlay
      nixpkgs-mozilla.overlay
      emacs-overlay.overlay
      (import ./fixups.nix)
      (import ./pkgs)
      (import ./pkgs/mdr.nix)
      (import ./nixos/overlay.nix)
      (final: prev: {
        stable = nixpkgs-stable.legacyPackages.x86_64-linux;
        flake-inputs = inputs;
      })
    ];
    legacyPackages.x86_64-linux = import nixpkgs {
      config = import ./config.nix;
      system = "x86_64-linux";
      overlays = self.overlays.default;
    };
    nixosConfigurations = self.legacyPackages.x86_64-linux.yorick.machine;
    homeConfigurations.yorick = home-manager.lib.homeManagerConfiguration {
      pkgs = self.legacyPackages.x86_64-linux;
      configuration = import ./home-manager/home.nix;
      system = "x86_64-linux";
      username = "yorick";
      stateVersion = "20.09";
      homeDirectory = "/home/yorick";
    };
    packages.x86_64-linux.yorick-home = self.homeConfigurations.yorick.activationPackage;

  };
}
