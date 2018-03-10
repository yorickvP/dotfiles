self: super: {
  spotify = super.spotify.overrideDerivation (attrs: rec {
    installPhase = builtins.replaceStrings
      ["wrapProgram $out/share/spotify/spotify"]
      ["wrapProgram $out/share/spotify/spotify --add-flags --force-device-scale-factor=\\$SPOTIFY_DEVICE_SCALE_FACTOR"]
      attrs.installPhase;
  });

  mpv = super.mpv.override { vaapiSupport = true; };
  polybar = super.polybar.override { i3GapsSupport = true; };
  python36Packages = super.python36Packages.override { overrides = (self: super: {
    # pycrypto runs slow tests by default
    pycrypto = super.pycrypto.overrideDerivation (attrs: {
      installCheckPhase = ''
        ${self.python.interpreter} nix_run_setup.py test --skip-slow-tests
      '';
    });
  }); };

  # wine = pkgs.wine.override { wineRelease = "staging"; wineBuild = "wineWow"; };
}
