{ lib, config, options, pkgs, ... }:
let
  y-firefox = pkgs.wrapFirefox pkgs.latest.firefox-bin.unwrapped {
    forceWayland = true;
    applicationName = "firefox";
  };
  thefuck-alias = shell:
    pkgs.runCommand "thefuck-alias" {
      TF_SHELL = shell;
      HOME = "/build";
    } "${pkgs.thefuck}/bin/thefuck -a > $out";
in {
  imports = [ ./desktop.nix ./emacs.nix ./lumi.nix ];
  nixpkgs = {
    config.allowUnfree = true;
    inherit (import /home/yorick/dotfiles/config.nix) overlays;
  };
  home = {
    stateVersion = "20.09";
    username = "yorick";
    homeDirectory = "/home/yorick";
  };
  programs = {
    starship = {
      enable = true;
      settings.nix_shell.disabled = false;
    };
    # todo: .aws/config default region
    gh = {
      enable = true;
      settings.aliases.co = "pr checkout";
    };
    direnv.enable = true;
    home-manager = {
      enable = true;
      path = toString /home/yorick/dotfiles;
    };
    git = {
      #lfs.enable = true;
      enable = true;
      userName = "Yorick van Pelt";
      userEmail = "yorick@yorickvanpelt.nl";
      signing.key = "A36E70F9DC014A15";
      signing.signByDefault = true;
      extraConfig.help.autocorrect = 5;
      extraConfig.push.default = "simple";
      extraConfig.pull.ff = "only";
      aliases = {
        lg =
          "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        st = "status";
        remotes = "remote -v";
        branches = "branch -a";
        tags = "tag";
        stashes = "stash list";
        unstage = "reset -q HEAD --";
        discard = "checkout --";
        uncommit = "reset --mixed HEAD~";
        graph =
          "log --graph -10 --branches --remotes --tags  --format=format:'%Cgreen%h %Creset• %<(75,trunc)%s (%cN, %cr) %Cred%d' --date-order    ";
        dad = "!curl https://icanhazdadjoke.com/ && git add";
      };
    };

    ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 120;
      controlMaster = "auto";
      matchBlocks = {
        "pub.yori.cc" = {
          user = "public";
          identityFile = "~/.ssh/id_rsa_pub";
          identitiesOnly = true;
        };
        phassa = {
          hostname = "karpenoktem.nl";
          port = 33933;
        };
        "karpenoktem.nl" = { user = "root"; };
        sankhara = {
          user = "infra";
          port = 33931;
          hostname = "sankhara.karpenoktem.nl";
        };
        blackadder.hostname = "10.209.0.6";
        frumar.hostname = "frumar.local";
        pennyworth.hostname = "pennyworth.yori.cc";
        smithers.hostname = "10.209.0.8";
        # "192.168.178.*" = {
        # only if wired
        #   extraOptions.Compression = "no";
        # };
      };
      extraConfig = ''
        Match host "192.168.*.*" exec "ip route get %h | grep -v -q via"
          Compression no
      '';
    };
    fish = {
      enable = true;
      shellAliases = {
        l = "ls";
        ls = "exa";
        nr = ''nix repl "<nixpkgs>"'';
        "n." = "nix repl .";
        nsp = "nix-shell -p";
        nsd = "nix show-derivation";
        nb = "nix build";
        nl = "nix log";
        g = "git";
        bc = "bluetoothctl connect 94:DB:56:79:7D:86";
        bd = "bluetoothctl disconnect 94:DB:56:79:7D:86";
      };
      interactiveShellInit = ''
        set fish_greeting
        source ${thefuck-alias "fish"}
        source ~/dotfiles/nr.fish
      '';
    };
    bash = {
      enable = true;
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      shellAliases = {
        nr = ''nix repl "<nixpkgs>"'';
        nsp = "nix-shell -p";
      };
      initExtra = ''
        source ${thefuck-alias "bash"}
        eval "$(broot --print-shell-function bash)"
        if [ "$IN_CACHED_NIX_SHELL" ]; then
          eval "$shellHook"
          unset shellHook
        fi
      '';
    };
  };
  xdg.configFile."nixpkgs/config.nix".text = ''
    import "${toString ../config.nix}"
  '';
  xdg.configFile."nixpkgs/overlays.nix".text = ''
    import "${toString ../overlays.nix}"
  '';
  xdg.configFile."streamlink/config".text = ''
    player = mpv --cache 2048
    default-stream = best
  '';
  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
  };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
  services.playerctld.enable = true;
  home.packages = (with pkgs; [
    ## utils
    # afew
    broot
    fd
    gcr.out
    git-absorb
    github-cli
    gmailieer
    htop
    kcachegrind
    lm_sensors
    notmuch
    watchman

    ## misc
    atop
    awscli
    borgbackup
    bup
    # catdoc
    expect
    fzf
    gitAndTools.git-annex
    glxinfo
    gnupg1
    imagemagick
    iodine
    jo
    jq
    lnav
    magic-wormhole
    man-pages
    mosh
    neofetch
    openssl
    pass
    pv
    screen
    sshfs-fuse
    sshuttle
    thefuck
    wakelan

    ## media
    aria2
    castnow
    nodePackages.peerflix
    streamlink
    yt-dlp

    ## code
    cloc
    gcc
    gdb
    git-crypt
    git-fire
    gnumake
    hub
    python3
    silver-searcher
    sqlite

    ## nix
    nix-tree
    niv
    nixfmt
    patchelf
    nix-prefetch-git
    nix-du
    nix-top
    nix-diff
    cachix
    cached-nix-shell

    ## js
    nodejs
    electron

    ## pdf
    ocamlPackages.cpdf
    zathura
    pandoc
    poppler_utils

    ## misc
    asciinema
    cargo
    exa
    linuxPackages.perf
    ltrace
    pssh
    smartmontools
    unzip
    vim
    xdg_utils
    #wlrctl

    ## coins
    electrum

    ## apps
    alacritty
    calibre
    chromium
    discord
    fanficfare
    feh
    gimp
    gopass
    hledger
    neomutt
    spotify
    tdesktop
    virt-manager
    wireshark
    y-firefox
    yubioath-desktop

    ## games
    minecraft
    steam
    # minecraft
    # nottetris2
    # openttd
    # wine
    # winetricks

  ]);

  home.file.".gnupg/gpg.conf".text = ''
    no-greeting
    require-cross-certification
    charset utf-8
    keyserver hkps://keys.openpgp.org
    #keyserver-options auto-key-retrieve
  '';
  home.file.".mutt" = {
    source = /home/yorick/dotfiles/mutt/.mutt;
    recursive = true;
  };
  manual.manpages.enable = false;
  home.sessionVariables = {
    HOME_MANAGER_CONFIG =
      toString ./home.nix; # unused, but checked for existence
  };
}
