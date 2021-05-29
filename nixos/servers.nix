let
  sources = import ./nix/sources.nix;
  nixpkgs = import sources.nixpkgs { };
  nixos = name: configuration:
    import (nixpkgs.path + "/nixos/lib/eval-config.nix") {
      extraArgs = { inherit name; };
      modules =
        [ ({ lib, ... }: { config.nixpkgs.pkgs = lib.mkDefault nixpkgs; }) ]
        ++ configuration;
    };
  names = [ "pennyworth" "jarvis" "blackadder" "woodhouse" "frumar" "zazu" ];
in nixpkgs.lib.genAttrs names (name:
  (let os = nixos name [ ./roles (./logical + "/${name}.nix") ];
  in os.config.system.build.toplevel // os))
