{
  description = "Yoricks dotfiles";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-mozilla.url = "github:mozilla/nixpkgs-mozilla";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-npm-buildpackage.url = "github:serokell/nix-npm-buildpackage";
    nix-npm-buildpackage.inputs.nixpkgs.follows = "nixpkgs";
    yobot.url = "git+https://git.yori.cc/yorick/yobot.git";
    # fooocus.url = "path:./pkgs/fooocus";
    ghostty.url = "github:ghostty-org/ghostty/26a42fac0ec8f612a3ddce60bab9842c79a2756a";
    ghostty.inputs.nixpkgs-stable.follows = "nixpkgs";
    ghostty.inputs.nixpkgs-unstable.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    call-flake.url = "github:divnix/call-flake";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      # nixpkgs-mozilla,
      emacs-overlay,
      nixos-hardware,
      agenix,
      nix-index-database,
      nix-npm-buildpackage,
      yobot,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
      self,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      fooocus = inputs.call-flake ./pkgs/fooocus;
      forAllSystems = lib.genAttrs [ "x86_64-linux" ];
      forAllSystemPkgs = f: forAllSystems (system: f self.legacyPackages.${system});
    in
    {
      legacyPackages = forAllSystems (
        system:
        import nixpkgs {
          config = {
            allowUnfree = true;
            # chromium.vaapiSupport = true;
            android_sdk.accept_license = true;
            permittedInsecurePackages = [ ];
            joypixels.acceptLicense = true;
          };
          inherit system;
          overlays = [ self.overlays.default ];
        }
      );

      packages = forAllSystemPkgs (pkgs: {
        yorick-home = self.homeConfigurations.${pkgs.stdenv.system}.activationPackage;
        default = pkgs.linkFarm "yori-nix" (
          [
            {
              name = "yorick-home";
              path = self.packages.${pkgs.stdenv.system}.yorick-home;
            }
          ]
          ++ (map (n: {
            name = n.toplevel.name;
            path = n.toplevel;
          }) (builtins.attrValues self.nixosConfigurations))
        );
      });

      homeConfigurations = forAllSystemPkgs (
        pkgs:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home-manager/home.nix
            nix-index-database.homeModules.nix-index
            {
              home = {
                username = "yorick";
                stateVersion = "20.09";
                homeDirectory = "/home/yorick";
              };
            }
          ];
        }
      );

      devShells = forAllSystemPkgs (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkgs.agenix
          ];
        };
      });
      overlays.default = nixpkgs.lib.composeManyExtensions [
        # nixpkgs-mozilla.overlay
        emacs-overlay.overlay
        agenix.overlays.default
        (final: prev: {
          pkgs-unstable = import nixpkgs-unstable {
            config.allowUnfree = true;
            inherit (final.stdenv) system;
          };
          flake-inputs = inputs // {
            inherit fooocus;
          };
          inherit (final.pkgs-unstable) claude-code govee2mqtt;
          nix-npm-buildpackage = nix-npm-buildpackage.legacyPackages."${final.stdenv.system}";
          fooocus = fooocus.packages.${final.stdenv.system}.default;
        })
        (import ./fixups.nix)
        (import ./pkgs)
        (import ./nixos/overlay.nix)
      ];
      nixosConfigurations = self.legacyPackages.x86_64-linux.yorick.machine;
    };
}
