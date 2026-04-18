let
  names = builtins.attrNames (builtins.readDir ./machines);
  listNixFiles =
    dir:
    let
      entries = builtins.readDir dir;
      isNixFile = name: entries.${name} == "regular" && builtins.match ".*\\.nix" name != null;
    in
    map (name: dir + "/${name}") (builtins.filter isNixFile (builtins.attrNames entries));
in
pkgs: super: {
  yorick = (super.yorick or { }) // rec {
    nixos =
      configuration: extraArgs:
      let
        c = pkgs.flake-inputs.nixpkgs.lib.nixosSystem {
          specialArgs.inputs = pkgs.flake-inputs;
          modules = [
            (
              { lib, ... }:
              {
                config.nixpkgs.pkgs = lib.mkDefault pkgs;
                config._module.args = extraArgs;
              }
            )
          ]
          ++ (if builtins.isList configuration then configuration else [ configuration ]);
        };
      in
      c.config.system.build // c;
    machine = pkgs.lib.genAttrs names (
      name: nixos ([ ./roles ] ++ listNixFiles (./machines + "/${name}")) { inherit name; }
    );
  };
}
