
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

    #wine = pkgs.wine.override { wineRelease = "staging"; wineBuild = "wineWow"; };

    ftb = pkgs.callPackage ./ftb.nix {};
    pyroscope = pkgs.callPackage ./pyroscope.nix {};
    peageprint = pkgs.callPackage ./peageprint.nix {};
    python35Packages = py3 // {
      # pycrypto runs slow tests by default
      pycrypto = py3.pycrypto.overrideDerivation (attrs: {
       installCheckPhase = ''
         ${py3.python.interpreter} nix_run_setup.py test --skip-slow-tests
       '';
      });
    };

    weiightminder = pkgs.callPackage (fetchgit {
      url = https://gist.github.com/yorickvP/229d21a7da13c9c514dbd26147822641;
      rev = "9749ef4d83c0078bc0248215ee882d7124827cf3";
      sha256 = "0kxi20ss2k22sv3ndplnklc6r7ja0lcgklw6mz43qcj7vmgxxllf";
    }) {};

    asterisk = pkgs.asterisk.overrideDerivation (attrs: rec {
      version = "13.11.2";

      src = fetchurl {
          url = "http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${version}.tar.gz";
          sha256 = "0fjski1cpbxap1kcjg6sgd6c8qpxn8lb1sszpg6iz88vn4dh19vf";
      };
    });
    mpv = pkgs.mpv.override { vaapiSupport = true; };


    yscripts = pkgs.callPackage ../dotfiles/bin {};


    envs = recurseIntoAttrs {

      de = mkEnv "y-de-deps" [
        gtk-engine-murrine
        hicolor_icon_theme
        vanilla-dmz
        # arc-theme
        libnotify
        rxvt_unicode-with-plugins
        arandr
        xorg.xrandr
        pavucontrol
        light nitrogen
      ];
      scripts = mkEnv "y-scripts" [
        peageprint
        weiightminder
      ];
      
      apps = mkEnv "y-apps" [
        gajim
        neomutt
        torbrowser
        chromium
        firefox-bin
        gimp
        tdesktop
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
        python gitAndTools.hub gnumake cloc silver-searcher
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
        steam
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
      ascanius = with envs; [apps code_min de games envs.js pdf nix media gcc misc scripts coins];
      jarvis = with envs; [apps code_min de games envs.js pdf nix media gcc misc scripts];
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
        mathtools
      ;
    });
  };

}

