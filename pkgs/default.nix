let
  addPatch = pkg: patch: pkg.overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [ patch ];
  });
  dir = builtins.readDir ./.;

  subdirs = builtins.filter
    (name: dir.${name} == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
    (builtins.attrNames dir);
in


(self: super: (
  builtins.listToAttrs (map
    (name: {
      inherit name;
      value = super.callPackage (./. + "/${name}") {};
    })
    subdirs)
) // {
  playerctl = addPatch super.playerctl ./playerctl-solid-emoji.diff;
  pay-respects = addPatch super.pay-respects ./pay-respects-yorinix.diff;
  ghostty = addPatch super.ghostty ./ghostty-delimiter.patch;

  # used for marvin tracker
  inherit (self.nix-npm-buildpackage) buildYarnPackage;
  python3 = super.python3.override {
    packageOverrides = pyself: pysuper: {
      libscrc = pyself.callPackage ./libscrc.nix { };
    };
  };
  # todo: bump wl-clipboard to master that has this patch
  wl-clipboard = addPatch super.wl-clipboard (self.fetchpatch {
    url = "https://puck.moe/up/zapap-suhih.patch";
    hash = "sha256-YiFDeBN1k2+lxVnWnU5sMpIJ7/zsVPEm5OZf0nHhzJA=";
  });
  # notion-desktop = self.callPackage ./notion-desktop {
  #   electron_26 = self.electron_28;
  # };
})
