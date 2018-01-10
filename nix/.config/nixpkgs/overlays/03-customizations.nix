self: super: {
  spotify = super.spotify.overrideDerivation (attrs: rec {
    installPhase = builtins.replaceStrings
      ["wrapProgram $out/share/spotify/spotify"]
      ["wrapProgram $out/share/spotify/spotify --add-flags --force-device-scale-factor=\\$SPOTIFY_DEVICE_SCALE_FACTOR"]
      attrs.installPhase;
  });

  mpv = super.mpv.override { vaapiSupport = true; };
  polybar = super.polybar.override {i3GapsSupport = true; githubSupport = false;};

  python36Packages = let py3 = super.python36Packages; in (py3 // {
    # pycrypto runs slow tests by default
    pycrypto = py3.pycrypto.overrideDerivation (attrs: {
      installCheckPhase = ''
        ${py3.python.interpreter} nix_run_setup.py test --skip-slow-tests
      '';
    });
  });
  i3-gaps = super.i3-gaps.overrideDerivation (attrs: {
    patches = [(super.fetchpatch {
      url = "https://github.com/Lucus16/i3/commit/65a5afda81ddd1618b4a62b7188173c82ee5f985.patch";
      sha256 = "1s943069afamizrz5pmll6cmrzgnlv3v93bmnykifhr0mnavbhph";
    })];
  });

  # wine = pkgs.wine.override { wineRelease = "staging"; wineBuild = "wineWow"; };
}
