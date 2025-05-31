{
  description = "Yoricks dotfiles";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-mozilla.url = "github:mozilla/nixpkgs-mozilla";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.05";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
    nixos-mailserver.inputs.nixpkgs-25_05.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-npm-buildpackage.url = "github:serokell/nix-npm-buildpackage";
    nix-npm-buildpackage.inputs.nixpkgs.follows = "nixpkgs";
    yobot.url = "git+https://git.yori.cc/yorick/yobot.git";
    fooocus.url = "path:./pkgs/fooocus";
    ghostty.url = "github:ghostty-org/ghostty";
    ghostty.inputs.nixpkgs-stable.follows = "nixpkgs";
    ghostty.inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    nixpkgs-unstable.follows = "nixpkgs";
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = inputs@{ nixpkgs, home-manager, nixpkgs-mozilla, emacs-overlay
                   , nixos-hardware, agenix, flake-utils
                   , nix-index-database, nix-npm-buildpackage
                   , yobot, ghostty
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
            permittedInsecurePackages = [];
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
            pkgs.agenix
          ];
        };

      })) // {
        overlays.default = nixpkgs.lib.composeManyExtensions [
          nixpkgs-mozilla.overlay
          emacs-overlay.overlay
          agenix.overlays.default
          (import ./fixups.nix)
          (import ./pkgs)
          (import ./pkgs/mdr.nix)
          (final: prev: {
            flake-inputs = inputs;
            nix-npm-buildpackage = nix-npm-buildpackage.legacyPackages."${final.system}";
            fooocus = inputs.fooocus.packages.${final.system}.default;
            ghostty = inputs.ghostty.packages.${final.system}.ghostty.overrideAttrs (o: {
              patches = (o.patches or []) ++ [
                ./pkgs/ghostty-delimiter.patch
              ];
            });
          })
          (import ./nixos/overlay.nix)
        ];
        nixosConfigurations = self.legacyPackages.x86_64-linux.yorick.machine;
      };
}
