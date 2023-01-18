{ lib, config, options, pkgs, ... }:
let
  thefuck-alias = shell:
    pkgs.runCommand "thefuck-alias" {
      TF_SHELL = shell;
      HOME = "/build";
    } "${pkgs.thefuck}/bin/thefuck -a > $out";
  headphones = "88:C9:E8:AD:73:E8";
in {
  imports = [ ./desktop.nix ./emacs.nix ./lumi.nix ];
  programs = {
    nix-index.enable = true;
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
    direnv.nix-direnv.enable = true;
    home-manager.enable = true;
    git = {
      #lfs.enable = true;
      enable = true;
      userName = "Yorick van Pelt";
      userEmail = "yorick@yorickvanpelt.nl";
      signing.key = "A36E70F9DC014A15";
      signing.signByDefault = true;
      includes = [{
        condition = "gitdir:~/tweag";
        contents.user.email = "yorick.vanpelt@tweag.io";
      }];
      extraConfig.merge.conflictStyle = "diff3";
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
        nr = ''nix repl --file "/home/yorick/dotfiles/repl.nix"'';
        "n." = "nix repl --file .";
        nsd = "nix show-derivation";
        nb = "nix build";
        nl = "nix log";
        g = "git";
        bc = "bluetoothctl connect ${headphones}";
        bd = "bluetoothctl disconnect ${headphones}";
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
        nr = ''nix repl "/home/yorick/dotfiles/repl.nix"'';
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
    builtins.trace "tried to read nixpkgs/config.nix" {}
  '';
  xdg.configFile."nixpkgs/overlays.nix".text = ''
    builtins.trace "tried to read nixpkgs/overlays.nix" []
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
    afew # mail
    broot
    fd
    gcr.out
    git-absorb
    github-cli
    lieer
    htop
    kcachegrind
    lm_sensors
    notmuch
    watchman
    nix-output-monitor

    ## misc
    moreutils
    atop
    awscli
    borgbackup
    bup
    # catdoc
    expect
    fzf
    fx
    gitAndTools.git-annex
    glxinfo
    gnupg1
    imagemagick
    iodine
    jo
    jless
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
    lz4json
    pssh
    smartmontools
    unzip
    vim
    xdg-utils
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
    yubioath-flutter

    ## games
    prismlauncher
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
    source = ../mutt/.mutt;
    recursive = true;
  };
  home.sessionVariables = {
    FLAKE_CONFIG_URI = "/home/yorick/dotfiles#homeConfigurations.${pkgs.stdenv.system}.activationPackage";
  };
}
