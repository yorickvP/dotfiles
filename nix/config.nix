
{
  allowUnfree = true;
  binaryCachePublicKeys = [ "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];
  firefox = {
    enableGoogleTalkPlugin = true;
    enableAdobeFlash = true;
  };

  chromium = {
    enablePepperFlash = true;
    enablePepperPDF = true;
  };

  packageOverrides = pkgs: with pkgs;
  let
    mkEnv = name: paths: pkgs.buildEnv { inherit name paths; };
    py = python35Packages; hs = haskellPackages; js = nodePackages; ml = ocamlPackages;
  in rec {
    firefox-bin-wrapper = wrapFirefox firefox-bin {};

    envs = recurseIntoAttrs {

      de = mkEnv "y-de-deps" [
        awesome
        compton-git
        hs.yeganesh dmenu
        gtk-engine-murrine
        i3lock
        scrot byzanz xclip
        rxvt_unicode-with-plugins
        arandr
        xorg.xrandr
        feh
      ];
      apps = mkEnv "y-apps" [
        # chromium
        firefox-bin-wrapper
        gimp
        hexchat
        #inkscape
        keepassx
        # libreoffice
        skype
        spotify
        kde4.quasselClientWithoutKDE
        sublime3
        leafpad
        calibre
        py.plover
      ];

      media = mkEnv "y-media" [
        js.peerflix
        py.livestreamer py.youtube-dl
        mpv
        aria2
      ];

      coins = mkEnv "y-coins" [
        altcoins.namecoin
        # altcoins.dogecoin
        electrum
      ];

      nix = mkEnv "y-nix" [
        patchelf nix nix-prefetch-git nix-repl nixops nox
      ];

      c = mkEnv "y-cdev" [
        valgrind cdecl gcc gdb ltrace cmake
      ];
      misc = mkEnv "y-misc" [
        gitAndTools.git-annex
        gnupg1 man-pages bup catdoc ghostscript
        imagemagick
        openjdk openssl
        pavucontrol
        sshfsFuse
        wireshark sshuttle iodine
      ];

      code = mkEnv "y-code" [
        cloc graphviz sloccount silver-searcher
        gnumake strace stack # hs?
        python3 dos2unix dhex
        # vcs
        gitAndTools.hub 

        # db
        sqliteInteractive
      ];

      wifimcu = mkEnv "wifimcu-dev" [
        minicom lrzsz lua
      ];

      games = mkEnv "y-games" [
        steam openttd wine winetricks minecraft
      ];

      js = mkEnv "y-jsdev" [
        js.jshint nodejs-5_x electron
      ];

      pdf = mkEnv "y-pdf" [
        ml.cpdf zathura pandoc poppler_utils
      ];

      xdev = mkEnv "y-xdev" [
        wmname xev xlsfonts xwininfo glxinfo
      ];

    };
  };

}

