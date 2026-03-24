{
  description = "Yoricks dotfiles";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    yobot.url = "git+https://git.yori.cc/yorick/yobot.git";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-amd-npu = {
      url = "github:datakami/nix-amd-npu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = { };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    google-workspace-cli = {
      url = "github:googleworkspace/cli/v0.9.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hackerdeck = {
      url = "git+https://git.yori.cc/yorick/hackerdeck";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.uv2nix.follows = "uv2nix";
      inputs.pyproject-build-systems.follows = "pyproject-build-systems";
    };
    muflax-blog = {
      url = "github:fmap/muflax65ngodyewp.onion";
    };
    nix-fast-build = {
      url = "github:Mic92/nix-fast-build";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      emacs-overlay,
      agenix,
      nix-index-database,
      self,
      ...
    }:
    let
      inherit (nixpkgs) lib;
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

      hydraJobs = lib.mapAttrs (_n: v: v.toplevel) self.nixosConfigurations // {
        inherit (self.packages.x86_64-linux) yorick-home;
        ci-shell = self.devShells.x86_64-linux.ci;
      };
      packages = forAllSystemPkgs (pkgs: {
        nix-fast-build = inputs.nix-fast-build.packages.${pkgs.stdenv.system}.default;
        yorick-home = self.homeConfigurations.${pkgs.stdenv.system}.activationPackage;
        default = pkgs.linkFarm "yori-nix" (
          [
            {
              name = "yorick-home";
              path = self.packages.${pkgs.stdenv.system}.yorick-home;
            }
          ]
          ++ (map (n: {
            inherit (n.toplevel) name;
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
            deadnix
            nixfmt-tree
            prek
            statix
          ];
          shellHook = ''
            prek install
          '';
        };
        ci = pkgs.mkShell {
          name = "ci";
          buildInputs = [
            self.packages.${pkgs.stdenv.system}.nix-fast-build
            pkgs.attic-client
            pkgs.mosquitto
          ];
        };
      });
      overlays.default = nixpkgs.lib.composeManyExtensions [
        emacs-overlay.overlay
        agenix.overlays.default
        inputs.llm-agents.overlays.default
        inputs.nix-amd-npu.overlays.default
        (final: _prev: {
          pkgs-unstable = import nixpkgs-unstable {
            config.allowUnfree = true;
            inherit (final.stdenv) system;
          };
          flake-inputs = inputs;
          inherit (final.pkgs-unstable) govee2mqtt;
          inherit (final.llm-agents) claude-code;
          gws = inputs.google-workspace-cli.packages.${final.stdenv.system}.default;
        })
        (import ./fixups.nix)
        (import ./pkgs)
        (import ./nixos/overlay.nix)
      ];
      nixosConfigurations = self.legacyPackages.x86_64-linux.yorick.machine;
    };
}
