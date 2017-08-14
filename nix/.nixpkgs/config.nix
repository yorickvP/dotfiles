
{
  allowUnfree = true;
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
    py2 = python27Packages; elm = elmPackages;

    overrideOlder = original: override: let
      newpkgver = lib.getVersion (override original);
      oldpkgver = lib.getVersion original;
      in if (lib.versionOlder oldpkgver newpkgver) then original.overrideDerivation override else original;

  in rec {

    #wine = pkgs.wine.override { wineRelease = "staging"; wineBuild = "wineWow"; };

    ftb = pkgs.callPackage ./ftb.nix {};
    pyroscope = pkgs.callPackage ./pyroscope {};
    peageprint = pkgs.callPackage ./peageprint.nix {};
    nottetris2 = pkgs.callPackage ./nottetris2.nix {};
    spotify = pkgs.spotify.overrideDerivation (attrs: rec {
      # version = "1.0.48.103.g15edf1ec-94";
      # name = "spotify-${version}";
      # src = fetchurl {
      #   url = "http://repository-origin.spotify.com/pool/non-free/s/spotify-client/spotify-client_${version}_amd64.deb";
      #   sha256 = "0rpwxgxv2ihfhlri98k4n87ynlcp569gm9q6hd8jg0vd2jgji8b3";
      # };
      installPhase = builtins.replaceStrings
        ["wrapProgram $out/share/spotify/spotify"]
        ["wrapProgram $out/share/spotify/spotify --add-flags --force-device-scale-factor=\\$SPOTIFY_DEVICE_SCALE_FACTOR"]
        attrs.installPhase;
    });
    python35Packages = py3 // {
      # pycrypto runs slow tests by default
      pycrypto = py3.pycrypto.overrideDerivation (attrs: {
       installCheckPhase = ''
         ${py3.python.interpreter} nix_run_setup.py test --skip-slow-tests
       '';
      });
    };

    gitFire = stdenv.mkDerivation {
      src = fetchFromGitHub {
        owner = "qw3rtman"; repo = "git-fire"; rev = "f485fffedbc4f719c55547be22ccd0080e592c9a";
        sha256 = "1f7m1rypir85p33bgaggw5kgxjv7qy69zn1ci3b26rxr2a06fqwy";
      };
      name = "git-fire";
      installPhase = ''
        mkdir -p $out/bin/
        install git-fire $out/bin/
      '';
    };

    libinput-gestures = pkgs.callPackage ./libinput-gestures.nix {};

    weiightminder = pkgs.callPackage (fetchgit {
      url = https://gist.github.com/yorickvP/229d21a7da13c9c514dbd26147822641;
      rev = "9749ef4d83c0078bc0248215ee882d7124827cf3";
      sha256 = "0kxi20ss2k22sv3ndplnklc6r7ja0lcgklw6mz43qcj7vmgxxllf";
    }) {};

    node2nix_git = (pkgs.callPackage (fetchFromGitHub {
        owner = "svanderburg";
        repo = "node2nix";
        rev = "b6545937592e7e54a14a2df315598570480fee9f";
        sha256 = "1y50gs5mk2sdzqx68lr3qb71lh7jp4c38ynybf8ikx7kfkzxvasb";
      }) {}).package;

    asterisk = overrideOlder pkgs.asterisk (attrs: rec {
      version = "13.11.2";

      src = fetchurl {
          url = "http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${version}.tar.gz";
          sha256 = "0fjski1cpbxap1kcjg6sgd6c8qpxn8lb1sszpg6iz88vn4dh19vf";
      };
    });
    mpv = pkgs.mpv.override { vaapiSupport = true; };
    # this can be dropped once i3status-2.11 is in unstable
    i3status = overrideOlder pkgs.i3status (attrs: rec {
      name = "i3status-2.11";

      src = fetchurl {
        url = "http://i3wm.org/i3status/${name}.tar.bz2";
        sha256 = "0pwcy599fw8by1a1sf91crkqba7679qhvhbacpmhis8c1xrpxnwq";
      };
    });

    streamlink = overrideOlder pkgs.streamlink (attrs: rec {
      version = "0.3.0";
      name = "streamlink-${version}";

      src = fetchFromGitHub {
        owner = "streamlink";
        repo = "streamlink";
        rev = "${version}";
        sha256 = "1bjih6y21vmjmsk3xvhgc1innymryklgylyvjrskqw610niai59j";
      };
    });
    streamer = if (builtins.hasAttr "streamlink" pkgs) then streamlink else pythonPackages.livestreamer;

    i3lock-color = overrideOlder pkgs.i3lock-color (attrs: rec {
      version = "2.7-2017-04-01";
      name = "i3lock-color-${version}";

      src = fetchFromGitHub {
        owner = "chrjguill";
        repo = "i3lock-color";
        rev = "61f6428aedbe4829d3e0f51d137283c8aec1e206";
        sha256 = "0h4nzx46kcsp6b1i2lm9y4d1w1icrpvjl8g1h3wbpa5x4crh4703";
      };
    });
    polybar = pkgs.polybar.override {i3GapsSupport = true; githubSupport = false;};

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
        sublime3
        leafpad
        # calibre
        #py2.plover
        wireshark meld
        discord
        fanficfare
        wpa_supplicant_gui
      ];

      media = mkEnv "y-media" [
        streamer
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
        # steam openttd wine winetricks minecraft
        # steam nottetris2 # ftb
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
    myEmacs = emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
      company
      paredit
      counsel
      flycheck
      ivy
      magit
      projectile
      use-package
      org-bullets
      solarized-theme
      evil
      evil-magit
      evil-leader
      evil-tutor
      evil-surround
      epkgs.evil-goggles
      # evil-commentary
      password-store
      pass
      linum-relative
      (epkgs.trivialBuild { pname = "emacs-nix-mode"; src = pkgs.fetchFromGitHub {
        owner = "matthewbauer";
        repo = "nix-mode";
        rev = "v1.2.1";
        sha256 = "1zpqpq6hd83prk80921nbjrvcmk0dykqrrr1mw3b29ppjma5zjiz";
      };
      preConfigure = ''
        rm nix-company.el nix-mode-mmm.el
      '';
      })
      nix-buffer
      which-key
      git-gutter-fringe
      neotree
      all-the-icons
      epkgs.org-cliplink
      pandoc-mode
      markdown-mode
      interleave
      # all-the-icons-dired
      org-ref
      avy
      # nixos-sandbox # https://github.com/travisbhartwell/nix-emacs
      haskell-mode
    ]));
    # todo: emacs-all-the-icons-fonts
    # install with nix-env -iAr nixos.hosts.$(hostname -s)
    # will remove all your previously installed nix-env stuff
    # so check with nix-env -q first
    hosts = {
      ascanius = with envs; [apps code de games envs.js pdf nix media gcc misc scripts coins];
      jarvis = with envs; [apps code de games envs.js pdf nix media gcc misc scripts];
      woodhouse = with envs; [de media misc kodi chromium spotify];
      pennyworth = [];
      frumar = with envs; [bup gitAndTools.git-annex rtorrent pyroscope];
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

