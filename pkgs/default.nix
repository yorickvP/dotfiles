let
  addPatches =
    pkg: patches:
    pkg.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ patches;
    });
  addPatch = pkg: patch: addPatches pkg [ patch ];
  dir = builtins.readDir ./.;

  subdirs = builtins.filter (
    name: dir.${name} == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
  ) (builtins.attrNames dir);
in

self: super:
(builtins.listToAttrs (
  map (name: {
    inherit name;
    value = super.callPackage (./. + "/${name}") { };
  }) subdirs
))
// {
  playerctl = addPatch super.playerctl ./playerctl-solid-emoji.diff;
  pay-respects = addPatch super.pay-respects ./pay-respects-yorinix.diff;
  ghostty = addPatch super.ghostty ./ghostty-revert-7185.patch;

  python3 = super.python3.override {
    packageOverrides = pyself: _pysuper: {
      libscrc = pyself.callPackage ./libscrc.nix { };
    };
  };
  lib = super.lib.extend (
    _lfinal: _lprev: {
      loadUvScript =
        script:
        let
          inherit (self) flake-inputs;

          scriptObj = flake-inputs.uv2nix.lib.scripts.loadScript {
            inherit script;
          };

          baseSet = self.callPackage flake-inputs.pyproject-nix.build.packages {
            python = self.python3;
          };

          pythonSet = baseSet.overrideScope (
            super.lib.composeManyExtensions [
              flake-inputs.pyproject-build-systems.overlays.wheel
              (scriptObj.mkOverlay {
                sourcePreference = "wheel";
              })
            ]
          );
        in
        self.writeScriptBin scriptObj.name (
          scriptObj.renderScript {
            venv = scriptObj.mkVirtualEnv {
              inherit pythonSet;
            };
          }
        );
    }
  );
}
