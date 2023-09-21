(self: super: {

  yori-cc = super.callPackage ./yori-cc.nix { };

  ftb = super.callPackage ./ftb.nix {};

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
  y-deployer = self.callPackage ../deployer/package.nix {
    inherit (self.nix-npm-buildpackage) buildYarnPackage;
  };
  grott = self.callPackage ./grott.nix {};
  python3 = super.python3.override {
    packageOverrides = pyself: pysuper: {
      libscrc = pyself.callPackage ./libscrc.nix {};
    };
  };
  xwaylandvideobridge = self.callPackage ./xwaylandvideobridge.nix {};
  timesync = self.flake-inputs.timesync.packages.${self.system}.default;
  wl-clipboard = super.wl-clipboard.overrideAttrs (o: {
    # todo (upgrade): remove version override on nixos-23.11
    src = super.fetchFromGitHub {
      owner = "bugaevc";
      repo = "wl-clipboard";
      rev = "v2.2.1";
      sha256 = "sha256-BYRXqVpGt9FrEBYQpi2kHPSZyeMk9o1SXkxjjcduhiY=";
    };
    version = "2023-05-03";
    # todo: upstream
    patches = (o.patches or []) ++ [
      (self.fetchpatch {
        url = "https://puck.moe/up/zapap-suhih.patch";
        hash = "sha256-YiFDeBN1k2+lxVnWnU5sMpIJ7/zsVPEm5OZf0nHhzJA=";
      })
    ];
  });
  calibre-web = super.calibre-web.overridePythonAttrs (o: {
    propagatedBuildInputs = o.propagatedBuildInputs ++ [ self.python3.pkgs.jsonschema ];
  });
  electron_27 = self.callPackage (self.path + /pkgs/development/tools/electron/binary/generic.nix) {} "27.0.0-beta.4" {
    x86_64-linux = "sha256-wdPRBf65Tzu2N4/chNVJtEhaPRuLjUEWsghYZ00aGag=";
    headers = "sha256-ZxvJrPrQX0UUy6LkXZcCXhUkRj6FLv40d7N65eGRRcY=";
  };
  notion-desktop = self.callPackage ./notion-desktop {
    inherit (self.nix-npm-buildpackage) buildYarnPackage;
    electron_26 = self.electron_27;
  };

})
