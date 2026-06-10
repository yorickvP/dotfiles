{
  config,
  pkgs,
  ...
}:
let
  pay-respects-alias =
    shell:
    pkgs.runCommand "pay-respects-alias" {
      HOME = "/build";
    } "${pkgs.pay-respects}/bin/pay-respects ${shell} --alias > $out";
  headphones = "80:99:E7:E4:01:78";
  emacsPackages = pkgs.emacsPackagesFor config.programs.emacs.package;
in
{
  programs = {
    nix-index.enable = true;
    # todo: .aws/config default region
    gh = {
      enable = true;
      settings.aliases.co = "pr checkout";
      settings.aliases.clone = "repo clone";
      settings.git_protocol = "ssh";
    };
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    home-manager.enable = true;
    # mergiraf.enable = true;
    git = {
      #lfs.enable = true;
      enable = true;
      signing.key = "A36E70F9DC014A15";
      signing.signByDefault = true;
      settings = {
        user.name = "Yorick van Pelt";
        user.email = "yorick@yorickvanpelt.nl";
        merge.conflictStyle = "diff3";
        help.autocorrect = 5;
        push.default = "simple";
        push.autoSetupRemote = true;
        pull.ff = "only";
        github.user = "yorickvP";
        init.defaultBranch = "main";
        rebase.autoSquash = true;
        branch.sort = "-committerdate";
      };
      ignores = [
        "/.envrc"
        "/.cache"
        "/.direnv"
        "/.aider.*"
        "/.claude/*.local.*"
      ];
      settings.alias = {
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        st = "status";
        remotes = "remote -v";
        branches = "branch -a";
        tags = "tag";
        stashes = "stash list";
        unstage = "reset -q HEAD --";
        discard = "checkout --";
        uncommit = "reset --mixed HEAD~";
        graph = "log --graph -10 --branches --remotes --tags  --format=format:'%Cgreen%h %Creset• %<(75,trunc)%s (%cN, %cr) %Cred%d' --date-order    ";
        dad = "!curl https://icanhazdadjoke.com/ && git add";
        ff = "merge --ff-only";
        force-pull = "!git fetch && git reset --hard @{u}";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          controlMaster = "auto";
          serverAliveInterval = 120;
          sendEnv = [
            "COLORTERM"
            "TERM_PROGRAM"
            "TERM_PROGRAM_VERSION"
          ];
          compression = true;
          forwardAgent = false;
          addKeysToAgent = "no";
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
        "pub.yori.cc" = {
          user = "public";
          identityFile = "~/.ssh/id_rsa_pub";
          identitiesOnly = true;
        };
        phassa = {
          hostname = "karpenoktem.nl";
          port = 33933;
        };
        "karpenoktem.nl" = {
          user = "root";
        };
        sankhara = {
          user = "infra";
          port = 33931;
          hostname = "sankhara.karpenoktem.nl";
        };
        blackadder.hostname = "10.209.0.6";
        frumar.hostname = "frumar.home.yori.cc";
        pennyworth.hostname = "pennyworth.yori.cc";
        smithers.hostname = "10.209.0.8";
        butterscotch.hostname = "10.209.0.10";
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
        ls = "eza";
        nr = ''nix repl --file "/home/yorick/dotfiles/repl.nix"'';
        "n." = "nix repl --file .";
        nsd = "nix show-derivation";
        nb = "nix build";
        nl = "nix log";
        g = "git";
        bc = "bluetoothctl connect ${headphones}";
        bcd = "bluetoothctl disconnect ${headphones}";
        bw-personal = "BITWARDENCLI_APPDATA_DIR=~/.config/Bitwarden\\ CLI\\ Personal bw";
        bw-work = "BITWARDENCLI_APPDATA_DIR=~/.config/Bitwarden\\ CLI\\ Work bw";
      };
      interactiveShellInit =
        let
          inherit (emacsPackages) vterm;
          vtermPath = "${vterm}/share/emacs/site-lisp/elpa/${vterm.pname}-${vterm.version}/etc/emacs-vterm.fish";
        in
        ''
          set fish_greeting
          source ${pay-respects-alias "fish"}
          source ~/dotfiles/nr.fish
          if test -n "$INSIDE_EMACS"
            source ${vtermPath}
          end
          function tmp --description 'cd to ~/tmp/YYYY-MM-DD, creating it if needed'
            set dated_tmp $HOME"/tmp/"(date +%Y-%m-%d)
            mkdir -p $dated_tmp
            cd $dated_tmp
          end
          bind alt-backspace backward-kill-word
          bind -M visual alt-backspace backward-kill-word
          bind -M insert alt-backspace backward-kill-word
        '';
      plugins = [
        { inherit (pkgs.fishPlugins.tide) name src; }
      ];
    };
    bash = {
      enable = true;
      historyControl = [
        "erasedups"
        "ignoredups"
        "ignorespace"
      ];
      shellAliases = {
        nr = ''nix repl "/home/yorick/dotfiles/repl.nix"'';
        nsp = "nix-shell -p";
      };
      initExtra = ''
        source ${pay-respects-alias "bash"}
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
  services.playerctld.enable = true;
  home.packages = with pkgs; [
    ## utils
    afew # mail
    fd
    gcr.out
    git-absorb
    github-cli
    lieer
    htop
    kdePackages.kcachegrind
    lm_sensors
    notmuch
    watchman
    nix-output-monitor
    appimage-run
    ripgrep
    zip
    age

    ## misc
    b3sum
    moreutils
    atop
    awscli2
    borgbackup
    bup
    # catdoc
    # trurl # fixme
    expect
    fzf
    fx
    git-annex
    mesa-demos
    gnupg1
    imagemagick
    iodine
    jo
    jless
    jq
    yq
    yj
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
    pay-respects
    wakelan
    tty-clock
    up

    ## media
    aria2
    castnow
    streamlink
    yt-dlp
    ffmpeg
    transmission-remote-gtk

    ## code
    cloc
    gcc
    gdb
    git-crypt
    git-fire
    gnumake
    python3
    silver-searcher
    sqlite-interactive
    noulith

    ## nix
    nix-tree
    niv
    nixfmt-rfc-style
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
    poppler-utils

    ## misc
    asciinema
    cargo
    eza
    perf
    ltrace
    lz4json
    pssh
    smartmontools
    unzip
    vim
    xdg-utils
    countfftabs
    spacer
    #wlrctl
    asciiquarium-transparent
    wakeonlan
    mqtt-explorer
    soco-cli # sonos speakers

    ## coins
    electrum
    ledger-live-desktop

    ## apps
    calibre
    chromium
    discord
    wayland-push-to-talk-fix
    fanficfare
    imv
    gimp
    gopass
    hledger
    spotify
    telegram-desktop
    signal-desktop
    virt-manager
    wireshark
    inkscape
    bitwarden-cli
    #yubioath-flutter
    gnucash
    thunderbird
    obsidian
    element-desktop
    libreoffice

    ## games
    # (prismlauncher.override { jdks = [ jdk21 ] })
    steam
    steam-run
    # minecraft
    # nottetris2
    # openttd
    # wine
    # winetricks
    kdePackages.kmines
    gamescope

    # work
    r8-cog
    mutagen
    # zoom-us
    google-cloud-sdk
    gws
    kubectl
    stern
    oath-toolkit
    mitmproxy
    magic-wormhole
    difftastic
    slack

    # admin
    nsc
    natscli

    yscripts.uv-landrun

    # llm stuff
    beads
    claude-box
    bubblewrap
    landrun
    claude-code
    llm-agents.ccusage

    # bitwarden-desktop
  ];

  home.sessionVariables = {
    FLAKE_CONFIG_URI = "/home/yorick/dotfiles#homeConfigurations.${pkgs.stdenv.system}.activationPackage";
  };
  # enabled by fish, slow
  programs.man.generateCaches = false;
  # uv
  home.sessionPath = [ "$HOME/.local/bin" ];
}
