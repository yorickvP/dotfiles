
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
    py3 = python35Packages; hs = haskellPackages; js = nodePackages; ml = ocamlPackages;
    py2 = python27Packages;
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
        pavucontrol
      ];
      apps = mkEnv "y-apps" [
        chromium
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
        py2.plover
        wireshark meld
      ];

      media = mkEnv "y-media" [
        js.peerflix
        py3.livestreamer py3.youtube-dl
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
        valgrind cdecl gdb ltrace cmake # gcc
      ];
      misc = mkEnv "y-misc" [
        gitAndTools.git-annex
        gnupg1 man-pages bup catdoc
        imagemagick
        openssl
        sshfsFuse
        sshuttle iodine stow
      ];

      code = mkEnv "y-code" [
        cloc graphviz sloccount silver-searcher
        gnumake strace stack # hs?
        (hiPrio python3) python dos2unix dhex
        # vcs
        gitAndTools.hub 

        # db
        sqliteInteractive
      ];

      wifimcu = mkEnv "wifimcu-dev" [
        minicom lrzsz lua
      ];

      java = mkEnv "y-java" [
        openjdk
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

