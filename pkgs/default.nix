(self: super: {

  yori-cc = super.callPackage ./yori-cc.nix { };

  ftb = super.callPackage ./ftb.nix {};
  # todo: python 2 -> 3
  pyroscope = self.stable.callPackage ./pyroscope {};

  yscripts = super.callPackage ../bin {};
  factorio = super.factorio.override {
    releaseType = "alpha";
    username = "yorickvp";
    token = (import ../nixos/secrets.nix).factorio_token;
  };
  playerctl = super.playerctl.overrideAttrs (o: {
    patches = (o.patches or []) ++ [ ./playerctl-solid-emoji.diff ];
  });

})
