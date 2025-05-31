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
  inherit (self.nix-npm-buildpackage) buildYarnPackage;
  marvin-tracker = self.callPackage ./marvin-tracker {};
  grott = self.callPackage ./grott.nix {};
  python3 = super.python3.override {
    packageOverrides = pyself: pysuper: {
      libscrc = pyself.callPackage ./libscrc.nix {};
    };
  };
  xwaylandvideobridge = self.libsForQt5.callPackage ./xwaylandvideobridge.nix {};
  timesync = self.flake-inputs.timesync.packages.${self.system}.default;
  wl-clipboard = super.wl-clipboard.overrideAttrs (o: {
    # todo: upstream
    patches = (o.patches or []) ++ [
      (self.fetchpatch {
        url = "https://puck.moe/up/zapap-suhih.patch";
        hash = "sha256-YiFDeBN1k2+lxVnWnU5sMpIJ7/zsVPEm5OZf0nHhzJA=";
      })
    ];
  });
  # notion-desktop = self.callPackage ./notion-desktop {
  #   electron_26 = self.electron_28;
  # };
  r8-cog = self.stdenvNoCC.mkDerivation rec {
    pname = "cog";
    version = "0.12.0";
    src = self.fetchurl {
      url = "https://github.com/replicate/cog/releases/download/v${version}/cog_linux_x86_64";
      hash = "sha256-Hi+eIlqIK8oGtf4fxR9H0y8qqsAzQ6Lq5HF/Mb0mD4M=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm 755 $src $out/bin/cog
      mkdir -p $out/share/{fish/vendor_completions.d,bash-completion/completions,zsh/site-functions}
      $out/bin/cog completion bash > $out/share/bash-completion/completions/cog
      $out/bin/cog completion fish > $out/share/fish/vendor_completions.d/cog.fish
      $out/bin/cog completion zsh > $out/share/zsh/site-functions/_cog
    '';
  };
  noulith = self.rustPlatform.buildRustPackage rec {
    pname = "noulith";
    version = "20231228";

    src = self.fetchFromGitHub {
      owner = "betaveros";
      rev = "3bce693335d8170895407846c237b6dad10ef7ec";
      repo = pname;
      hash = "sha256-Ye/Htcp9lrRo80ix4QQ+lDZSmpDSA6t1MCcWL6yTvGg=";
    };
    buildFeatures = [ "cli" "request" "crypto" ];


    cargoHash = "sha256-9mGswL1QberwXpO0qj7NbyY5zozWj88dwCCY6kQ92uU";
    nativeBuildInputs = [ self.pkg-config ];
    buildInputs = [ self.openssl.dev ];
  };
  llm = super.callPackage ./llm.nix {
    python3 = self.python312;
  };
  govee2mqtt = super.callPackage ./govee2mqtt.nix { inherit (super) govee2mqtt; };
  play-nijmegen-calendar = super.callPackage ./play-nijmegen-calendar/default.nix {};
  proquint = super.callPackage ({ python3 }: python3.pkgs.buildPythonPackage rec {
    pname = "proquint";
    version = "0.2.1";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "0dda5h3lc4mv5sch1cvdjk4hvcng6nzabbpby2f7vvbf5x61mmij";
    };
    checkInputs = with python3.pkgs; [ nose hypothesis ];
    pythonImportsCheck = [ "proquint" ];

    meta = {
      description =
        "Proquints: Identifiers that are Readable, Spellable, and Pronounceable";
      homepage = "https://pypi.org/project/proquint/";
    };
  }) {};
  wg-restarter = self.buildGoModule {
    name = "wg-restarter";
    src = ./wg-restarter;
    vendorHash = null;
  };
  claude-desktop = super.callPackage ./claude-desktop.nix {};
  transmission_405 = super.transmission_4.overrideAttrs {
    version = "4.0.5";
    src = self.fetchFromGitHub {
      owner = "transmission";
      repo = "transmission";
      rev = "4.0.5";
      hash = "sha256-gd1LGAhMuSyC/19wxkoE2mqVozjGPfupIPGojKY0Hn4=";
      fetchSubmodules = true;
    };
  };
})
