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
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-npm-buildpackage.url = "github:serokell/nix-npm-buildpackage";
    nix-npm-buildpackage.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ nixpkgs, home-manager, nixpkgs-mozilla, emacs-overlay
                   , nixpkgs-wayland, nixpkgs-stable, nixos-hardware, agenix, flake-utils
                     , nix-index-database, nix-npm-buildpackage
                   , self
    , ... }:
    (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = self.legacyPackages.${system};
      in {
        legacyPackages = import nixpkgs {
          config = {
            allowUnfree = true;
            # chromium.vaapiSupport = true;
            android_sdk.accept_license = true;
          };
          inherit system;
          overlays = [ self.overlays.default ];
        };

        packages = {
          yorick-home = self.homeConfigurations.${system}.activationPackage;
          default = pkgs.linkFarm "yori-nix" ([{
            name = "yorick-home";
            path = self.packages.${system}.yorick-home;
          }] ++ (map (n: {
            name = n.toplevel.name;
            path = n.toplevel;
          }) (builtins.attrValues self.nixosConfigurations)));
        };

        homeConfigurations = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home-manager/home.nix
            nix-index-database.hmModules.nix-index
            {
              home = {
                username = "yorick";
                stateVersion = "20.09";
                homeDirectory = "/home/yorick";
              };
            }
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            y-deployer
          ];
        };
        devShells.deployer = pkgs.mkShell {
          buildInputs = with pkgs; [
            yarn
            nodePackages.typescript-language-server
          ];
        };

        apps.default = flake-utils.lib.mkApp {
          drv = pkgs.y-deployer;
        };
        # updater script for home profile
        # works around https://github.com/nix-community/home-manager/issues/2848
        apps.update-home = flake-utils.lib.mkApp {
          drv = pkgs.writeScriptBin "update-home" ''
            set -euo pipefail
            old_profile=$(nix profile list | grep home-manager-path | head -n1 | awk '{print $4}')
            echo $old_profile
            nix profile remove $old_profile
            ${
              self.packages.${system}.yorick-home
            }/activate || (echo "restoring old profile"; ${pkgs.nix}/bin/nix profile install $old_profile)
          '';
        };
      })) // {
        overlays.default = nixpkgs.lib.composeManyExtensions [
          nixpkgs-wayland.overlay
          nixpkgs-mozilla.overlay
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
            nix-npm-buildpackage = nix-npm-buildpackage.legacyPackages."${final.system}";
          })
          (import ./nixos/overlay.nix)
        ];
        nixosConfigurations = self.legacyPackages.x86_64-linux.yorick.machine;
      };
}
