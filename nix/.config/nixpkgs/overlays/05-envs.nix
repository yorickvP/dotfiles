self: super: with super;
let
  mkEnv = name: paths: buildEnv {inherit name paths; };
  py3 = python36Packages; hs = haskellPackages; js = nodePackages; ml = ocamlPackages;
  py2 = python27Packages; elm = elmPackages;
in {
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
      dropbox # really?
      # wpa_supplicant_gui
      xclip siji fira-mono playerctl font-awesome-ttf
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
      #firefox-bin
      gimp
      tdesktop
      #hexchat
      #inkscape
      keepassx
      # libreoffice
      # skype
	    spotify
      quasselClient
      leafpad
      calibre
      wpa_supplicant_gui
      #py2.plover
      wireshark meld
      discord
      fanficfare
      hledger hledger-web
    ];

    media = mkEnv "y-media" [
      streamlink
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
      patchelf nix nix-prefetch-git nix-repl nixopsUnstable nox
    ];

    c = mkEnv "y-cdev" [
      valgrind cdecl gdb ltrace cmake radare2 # gcc
    ];
    misc = mkEnv "y-misc" [
      #gitAndTools.git-annex # doesn't build
      gnupg1 man-pages bup # catdoc
      imagemagick
      openssl
      sshfsFuse
      sshuttle iodine stow
      expect duplicity
      wakelan x2x pass
      abduco dvtm w3m
      jq jo
    ];

    code = mkEnv "y-code" [
      python gitAndTools.hub gnumake cloc silver-searcher gitFire gti
    ];
    java = openjdk;

    games = mkEnv "y-games" [
      # steam openttd wine winetricks minecraft nottetris2
      steam
    ];

    js = mkEnv "y-jsdev" [
      js.jshint nodejs-6_x electron node2nix_git
    ];

    pdf = mkEnv "y-pdf" [
      ml.cpdf zathura pandoc poppler_utils
    ];
    hs = mkEnv "y-hs" [
      ghc stack cabal-install
    ];

  };
  # install with nix-env -iAr nixos.hosts.$(hostname -s)
  # will remove all your previously installed nix-env stuff
  # so check with nix-env -q first
  hosts = with self; with self.envs; {
    ascanius = [apps code de games envs.js pdf nix media gcc misc scripts coins];
    jarvis = [apps code de games envs.js pdf nix media gcc misc scripts myEmacs];
    woodhouse = [de media misc kodi chromium spotify];
    pennyworth = [];
    frumar = [bup gitAndTools.git-annex rtorrent pyroscope];
  };

}
