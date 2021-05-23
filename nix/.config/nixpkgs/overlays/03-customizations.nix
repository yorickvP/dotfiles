self: super: {
  #mpv = super.mpv.override { vaapiSupport = true; };
  python36Packages = super.python36Packages.override { overrides = (self: super: {
    # pycrypto runs slow tests by default
    pycryptodome = super.pycryptodome.overrideDerivation (attrs: {
      doCheck = false;
      doInstallCheck = false;
      setuptoolsCheckPhase = "true";
      # installCheckPhase = ''
      #   ${self.python.interpreter} nix_run_setup.py test --skip-slow-tests
      # '';
    });
  }); };
  # emacs-pgtk = with self; emacs26.overrideAttrs (
  #   { configureFlags ? [], postPatch ? "", nativeBuildInputs ? [], ... }:
  #   {
  #     src = fetchFromGitHub {
  #       owner = "masm11";
  #       repo = "emacs";
  #       rev = "d56f600d1ca2e996bedc6a59a85abc983bb3f23d";
  #       sha256 = "06wycfmr1w3lgpg10ffad1i2sr9ryac54w8qsavhn3h0rlvivjd3";
  #     };

  #     patches = [];

  #     nativeBuildInputs = nativeBuildInputs ++ [ autoreconfHook texinfo ];

  #     configureFlags = configureFlags ++ [ "--without-x" "--with-cairo" "--with-modules" ];
  #   }
  # );


  # wine = pkgs.wine.override { wineRelease = "staging"; wineBuild = "wineWow"; };
}
