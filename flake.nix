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
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    serokell-nix.url = "github:serokell/serokell.nix";
    serokell-nix.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ nixpkgs, home-manager, nixpkgs-mozilla, emacs-overlay
    , nixpkgs-wayland, nixpkgs-stable, nixos-hardware, agenix, serokell-nix, self, ... }: {
      overlays.default = nixpkgs.lib.composeManyExtensions [
        nixpkgs-wayland.overlay
        #nixpkgs-mozilla.overlay
        emacs-overlay.overlay
        agenix.overlay
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
        overlays = builtins.attrValues self.overlays;
      };
      nixosConfigurations = self.legacyPackages.x86_64-linux.yorick.machine;
      homeConfigurations.x86_64-linux =
        home-manager.lib.homeManagerConfiguration {
          pkgs = self.legacyPackages.x86_64-linux;
          modules = [
            ./home-manager/home.nix
            {
              home = {
                username = "yorick";
                stateVersion = "20.09";
                homeDirectory = "/home/yorick";
              };
            }
          ];
        };
      packages.x86_64-linux.yorick-home =
        self.homeConfigurations.x86_64-linux.activationPackage;
      apps.x86_64-linux.update-home = {
        type = "app";
        program = (self.legacyPackages.x86_64-linux.writeScript "update-home" ''
          set -euo pipefail
          old_profile=$(nix profile list | grep home-manager-path | head -n1 | awk '{print $4}')
          echo $old_profile
          nix profile remove $old_profile
          ${self.packages.x86_64-linux.yorick-home}/activate || (echo "restoring old profile"; ${self.legacyPackages.x86_64-linux.nix}/bin/nix profile install $old_profile)
        '').outPath;
      };

    };
}
