
{
  allowUnfree = true;
  #binaryCachePublicKeys = [ "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];
  firefox = {
    enableGoogleTalkPlugin = true;
    enableAdobeFlash = true;
  };

  # chromium = {
  #   enablePepperFlash = true;
  #   enablePepperPDF = true;
  # };

  packageOverrides = pkgs: with pkgs;
  let
    mkEnv = name: paths: pkgs.buildEnv { inherit name paths; };
    py3 = python35Packages; hs = haskellPackages; js = nodePackages; ml = ocamlPackages;
    py2 = python27Packages; emc = emacsPackages; emcn = emacsPackagesNg; elm = elmPackages;
  in rec {
    org = pkgs.emacsPackages.org.overrideDerivation (attrs: {
      nativeBuildInputs = [emacs texinfo tetex]; });

    wine = pkgs.wine.override { wineRelease = "staging"; wineBuild = "wineWow"; };

    ftb = pkgs.callPackage ./ftb.nix {};
    pyroscope = pkgs.callPackage ./pyroscope.nix {};


    envs = recurseIntoAttrs {

      de = mkEnv "y-de-deps" [
        gtk-engine-murrine
        hicolor_icon_theme
        arc-gtk-theme
        libnotify
        scrot byzanz xclip
        #rxvt_unicode-with-plugins
        arandr
        xorg.xrandr
        feh
        pavucontrol
      ];
      apps = mkEnv "y-apps" [
        gajim
        mutt
        torbrowser
        chromium
        firefox-bin
        gimp
        #hexchat
        #inkscape
        keepassx
        # libreoffice
        skype
        spotify
        kde4.quasselClientWithoutKDE
        sublime3
        leafpad
        calibre
        #py2.plover
        wireshark meld
      ];

      media = mkEnv "y-media" [
        py3.livestreamer
        py3.youtube-dl
        mpv
        aria2
      ];

      coins = mkEnv "y-coins" [
        # altcoins.namecoin
        # altcoins.dogecoin
        electrum
      ];

      nix = mkEnv "y-nix" [
        patchelf nix nix-prefetch-git nix-repl nixops nox
      ];

      c = mkEnv "y-cdev" [
        valgrind cdecl gdb ltrace cmake # gcc
      ];
      misc = mkEnv "y-misc" [
        #gitAndTools.git-annex # doesn't build
        gnupg1 man-pages bup # catdoc
        imagemagick
        openssl
        sshfsFuse
        sshuttle iodine stow
        expect duplicity
        wakelan x2x
      ];

      emacs = mkEnv "y-emacs" [emacs org emcn.smex emcn.agda2-mode emc.colorThemeSolarized];
      code_min = mkEnv "y-codemin" [
        python gitAndTools.hub gnumake cloc
      ];
      code = mkEnv "y-code" [
        cloc graphviz sloccount silver-searcher
        gnumake strace stack # hs?
        # TODO: patch sublime3 haskell integration for stack (correct hsdev version)
        (hiPrio python3) python dos2unix dhex
        # elm.elm # agda
        # vcs
        gitAndTools.hub subversion

        # db
        sqliteInteractive
      ];

      wifimcu = mkEnv "wifimcu-dev" [
        minicom lrzsz lua
      ];

      java = openjdk;

      # java = mkEnv "y-java" [
      #   openjdk
      # ];

      games = mkEnv "y-games" [
        # steam openttd wine winetricks minecraft
        openttd # steam
      ];

      js = mkEnv "y-jsdev" [
        js.jshint nodejs-6_x electron
      ];

      pdf = mkEnv "y-pdf" [
        ml.cpdf zathura pandoc poppler_utils
      ];

      xdev = mkEnv "y-xdev" [
        wmname xev xlsfonts xwininfo glxinfo
      ];

    };
    hosts = {
      ascanius = with envs; [apps code_min de games envs.js pdf nix media gcc misc];
      woodhouse = with envs; [de media misc kodi chromium spotify];
      pennyworth = [];
      frumar = with envs; [bup git-annex rtorrent pyroscope];
    };
    pandocdeps = (pkgs.texlive.combine {
      inherit (pkgs.texlive)
        scheme-basic
        # explicit list pandoc tex dependencies
        amsfonts amsmath lm ec ifxetex ifluatex eurosym listings fancyvrb
        # longtable
        booktabs
        hyperref ulem geometry setspace
        # linestretch
        babel
        # some optional dependencies of pandoc
        upquote microtype csquotes
      ;
    });
  };

}

