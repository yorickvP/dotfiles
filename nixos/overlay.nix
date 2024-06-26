let names = [ "pennyworth" "jarvis" "blackadder" "frumar" "smithers" ];
in pkgs: super: {
  yorick = (super.yorick or { }) // rec {
    nixos = configuration: extraArgs:
      let
        c = import (pkgs.path + "/nixos/lib/eval-config.nix") {
          inherit (pkgs.stdenv.hostPlatform) system;
          specialArgs.inputs = pkgs.flake-inputs;
          modules =
            [ ({ lib, ... }: {
              config.nixpkgs.pkgs = lib.mkDefault pkgs;
              config.nixpkgs.flake.source = pkgs.flake-inputs.nixpkgs;
              config._module.args = extraArgs;
            }) ]
            ++ (if builtins.isList configuration then
              configuration
            else
              [ configuration ]);
        };
      in c.config.system.build // c;
    machine = pkgs.lib.genAttrs names
      (name: nixos [ ./roles (./machines + "/${name}/default.nix") ] { inherit name; });
  };
}
