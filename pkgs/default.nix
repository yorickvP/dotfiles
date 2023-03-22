(self: super: {

  yori-cc = super.callPackage ./yori-cc.nix { };

  ftb = super.callPackage ./ftb.nix {};
  # todo: python 2 -> 3
  pyroscope = self.nixpkgs-stable.callPackage ./pyroscope {};

  yscripts = super.callPackage ../bin {};
  factorio = super.factorio.override {
    releaseType = "alpha";
    username = "yorickvp";
    token = (import ../nixos/secrets.nix).factorio_token;
  };
  playerctl = super.playerctl.overrideAttrs (o: {
    patches = (o.patches or []) ++ [ ./playerctl-solid-emoji.diff ];
  });
  countfftabs = super.callPackage ./countfftabs {};
  lz4json = super.stdenv.mkDerivation (o: {
    pname = "lz4json";
    version = "20191229";
    src = super.fetchFromGitHub {
      repo = o.pname;
      owner = "andikleen";
      rev = "c44c51005c505de2636cc1e59cde764490de7632";
      hash = "sha256-rLjJ7qy7Tx0htW1VxrfCCqVbC6jNCr9H2vdDAfosxCA=";
    };
    buildInputs = [ super.lz4 ];
    nativeBuildInputs = [ super.pkg-config ];
    installPhase = ''
      runHook preInstall
      install -D -t $out/bin lz4jsoncat
      runHook postInstall
    '';
  });
  wayland-push-to-talk-fix = self.callPackage ./wayland-push-to-talk-fix.nix {};

})
