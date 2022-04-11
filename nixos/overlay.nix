let names = [ "pennyworth" "jarvis" "blackadder" "frumar" "zazu" "smithers" ];
in pkgs: super: {
  yorick = (super.yorick or { }) // rec {
    nixos = configuration: extraArgs:
      let
        c = import (pkgs.path + "/nixos/lib/eval-config.nix") {
          inherit (pkgs.stdenv.hostPlatform) system;
          modules =
            [ ({ lib, ... }: {
              config.nixpkgs.pkgs = lib.mkDefault pkgs;
              config._module.args = extraArgs;
            }) ]
            ++ (if builtins.isList configuration then
              configuration
            else
              [ configuration ]);
        };
      in c.config.system.build // c;
    machine = pkgs.lib.genAttrs names
      (name: nixos [ ./roles (./logical + "/${name}.nix") ] { inherit name; });
  };
}
