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
  y-deployer = self.callPackage ../deployer/package.nix {};
  inherit (self.nix-npm-buildpackage) buildYarnPackage;
  marvin-tracker = self.callPackage ./marvin-tracker {};
  grott = self.callPackage ./grott.nix {};
  python3 = super.python3.override {
    packageOverrides = pyself: pysuper: {
      libscrc = pyself.callPackage ./libscrc.nix {};
    };
  };
  xwaylandvideobridge = self.callPackage ./xwaylandvideobridge.nix {};
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
  notion-desktop = self.callPackage ./notion-desktop {
    electron_26 = self.electron_27;
  };
  r8-cog = self.stdenvNoCC.mkDerivation rec {
    pname = "cog";
    version = "0.8.6";
    src = self.fetchurl {
      url = "https://github.com/replicate/cog/releases/download/v${version}/cog_linux_x86_64";
      hash = "sha256-Ng62tbRmlrL23JRdP3Zt4nT8JfLrHThF0mmMf1jee7g=";
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
  obsidian = with self.lib; throwIf (versionOlder "1.4.16" super.obsidian.version) "Obsidian no longer requires EOL Electron" (
    super.obsidian.override {
      electron = self.electron_25.overrideAttrs (_: {
        preFixup = "patchelf --add-needed ${self.libglvnd}/lib/libEGL.so.1 $out/bin/electron"; # NixOS/nixpkgs#272912
        meta.knownVulnerabilities = [ ]; # NixOS/nixpkgs#273611
      });
    }
  );
})
