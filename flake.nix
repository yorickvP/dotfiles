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
  outputs = inputs@{ nixpkgs, home-manager, nixpkgs-mozilla, emacs-overlay
    , nixpkgs-wayland, nixpkgs-stable, nixos-hardware, self, ... }: {
      overlay = nixpkgs.lib.composeManyExtensions [
        nixpkgs-wayland.overlay
        #nixpkgs-mozilla.overlay
        emacs-overlay.overlay
        (import ./fixups.nix)
        (import ./pkgs)
        (import ./pkgs/mdr.nix)
        (final: prev: {
          nixpkgs-stable = import nixpkgs-stable {
            system = prev.stdenv.system;
            config = { };
            overlays = [ ];
          };
          flake-inputs = inputs;
        })
        (import ./nixos/overlay.nix)
      ];
      legacyPackages.x86_64-linux = import nixpkgs {
        config = {
          allowUnfree = true;
          # chromium.vaapiSupport = true;
          android_sdk.accept_license = true;
        };
        system = "x86_64-linux";
        overlays = [ self.overlay ];
      };
      nixosConfigurations = self.legacyPackages.x86_64-linux.yorick.machine;
      homeConfigurations.x86_64-linux =
        home-manager.lib.homeManagerConfiguration {
          pkgs = self.legacyPackages.x86_64-linux;
          configuration = import ./home-manager/home.nix;
          system = "x86_64-linux";
          username = "yorick";
          stateVersion = "20.09";
          homeDirectory = "/home/yorick";
        };
      packages.x86_64-linux.yorick-home =
        self.homeConfigurations.x86_64-linux.activationPackage;

    };
}