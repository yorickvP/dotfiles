{ lib, config, options, pkgs, ... }:
let
  y-firefox = pkgs.wrapFirefox pkgs.latest.firefox-beta-bin.unwrapped {
    forceWayland = true;
    browserName = "firefox";
  };
  thefuck-alias = shell: pkgs.runCommand "thefuck-alias" {
    TF_SHELL = shell;
  } "${pkgs.thefuck}/bin/thefuck -a > $out";
in {
  imports = [ ./arbtt.nix ./libinput-gestures.nix ./desktop.nix ];
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
    gh = {
      enable = true;
      aliases.co = "pr checkout";
    };
    direnv.enable = true;
    home-manager = {
      enable = true;
      path = toString /home/yorick/dotfiles;
    };
    emacs = {
      enable = true;
      package = pkgs.emacsPgtkGcc;
      extraPackages = _:
        let epkgs = pkgs.emacsPackagesFor pkgs.emacsPgtkGcc;
        in (with epkgs.melpaPackages; [
          reason-mode
          evil
          counsel
          ivy
          ivy-hydra
          swiper
          magit
          forge
          avy
        ]) ++ (with epkgs.melpaPackages; [
          epkgs.undo-tree
          epkgs.notmuch
          epkgs.rust-mode
          company
          projectile
          counsel-projectile
          ggtags
          use-package
          org-bullets
          solarized-theme
          evil-leader
          evil-surround # evil-magit
          epkgs.evil-goggles
          epkgs.ox-mediawiki
          nix-buffer
          which-key
          git-gutter-fringe
          all-the-icons
          epkgs.org-cliplink
          pandoc-mode
          markdown-mode
          #interleave
          org-ref
          haskell-mode
          request # intero
          weechat
          s
          elixir-mode
          htmlize
          linum-relative
          terraform-mode
          direnv
          vue-mode
          solarized-theme
          #wlrctl
          (epkgs.melpaBuild {
            pname = "nix-mode";
            version = "1.4.0";
            packageRequires = [ json-mode epkgs.mmm-mode company ];
            recipe = pkgs.writeText "recipe" ''
              (nix-mode
               :repo "nixos/nix-mode" :fetcher github
               :files ("nix*.el"))
            '';
            src = pkgs.fetchFromGitHub {
              owner = "nixos";
              repo = "nix-mode";
              rev = "ddf091708b9069f1fe0979a7be4e719445eed918";
              sha256 = "0s8ljr4d7kys2xqrhkvj75l7babvk60kxgy4vmyqfwj6xmcxi3ad";
            };
          })
        ]);
    };
    git = {
      enable = true;
      userName = "Yorick van Pelt";
      userEmail = "yorick@yorickvanpelt.nl";
      signing.key = "A36E70F9DC014A15";
      signing.signByDefault = true;
      extraConfig.help.autocorrect = 5;
      extraConfig.push.default = "simple";
      extraConfig.pull.ff = "only";
      extraConfig."includeIf \"gitdir:~/serokell/\"".path =
        "~/serokell/.gitconfig";
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
      matchBlocks = let
        lumigod = hostname: {
          inherit hostname;
          port = 2233;
          user = "yorick.van.pelt";
        };
        lumivpn = {
          user = "yorick.van.pelt";
          # verified by wireguard key
          extraOptions.StrictHostKeyChecking = "no";
        };
        in rec {
        "pub.yori.cc" = {
          user = "public";
          identityFile = "~/.ssh/id_rsa_pub";
          identitiesOnly = true;
        };
        phassa = {
          hostname = "karpenoktem.nl";
          port = 33933;
        };
        athena = {
          hostname = "athena.lumi.guide";
          user = "yorick.van.pelt";
        };
        rpibuild3 = {
          hostname = "10.110.0.3";
          user = "yorick.van.pelt";
          port = 4222;
        };
        styx = lumigod "10.110.0.1";
        "*.lumi.guide" = { user = "yorick.van.pelt"; };
        zeus = lumigod "zeus.lumi.guide";
        ponos = lumigod "ponos.lumi.guide";
        medusa = lumigod "lumi.guide";
        # signs
        "10.108.0.*" = lumivpn // { port = 4222; };
        "10.109.0.*" = lumivpn;
        "10.110.0.*" = lumivpn // { port = 2233; };
        "10.111.0.*" = lumivpn;
        "192.168.42.*" = {
          user = "yorick.van.pelt";
        };
        # "192.168.178.*" = {
        # only if wired
        #   extraOptions.Compression = "no";
        # };
      };
      extraConfig = ''
        Match host "192.168.*.*" exec "ip route get %h | grep -v -q via"
          Compression no
        Match host "192.168.42.*" exec "ip route get %h | grep -q via"
          ProxyJump athena
      '';
    };
    fish = {
      enable = true;
      shellAliases = {
        l = "ls";
        ls = "exa";
        nr = ''nix repl "<nixpkgs>"'';
        nsp = "nix-shell -p";
      };
      interactiveShellInit = ''
        source ${thefuck-alias "fish"}
        starship init fish | source
        source ~/dotfiles/nr.fish
      '';
      promptInit = "set fish_greeting";
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
        eval "$(starship init bash)"
      '';
    };
  };
  home.file.".emacs.d/init.el" = {
    source = (toString /home/yorick/dotfiles/emacs/.emacs.d/init.el);
  };
  xdg.configFile."streamlink/config".text = ''
    player = mpv --cache 2048
    default-stream = best
  '';
  services = {
    lorri.enable = true;
    #arbtt.enable = true;
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };
  home.packages = with pkgs.envs;
    [ apps code games pdf media misc scripts coins js ] ++ (with pkgs; [
      github-cli
      nix-tree
      virt-manager
      watchman
      gnome3.gcr.out # alacritty
      notmuch
      gmailieer
      git-absorb
      afew
      broot
      starship
      fd
      htop
      kcachegrind
      lm_sensors
      niv
      nixfmt
      linuxPackages.perf
      pssh
      smartmontools
      vim
      xdg_utils
      nix-top
      nix-diff
      ltrace
      asciinema
      cargo
      minecraft
      unzip
      exa
      cachix
      y-firefox
    ]); # qtwayland
  # systemd.user.services.gmi = {
  #   Unit = {
  #     Description = "gmi";
  #   };
  #   Service = {
  #     CPUSchedulingPolicy = "idle";
  #     IOSchedulingClass = "idle";
  #     WorkingDirectory = "/home/yorick/mail/account.gmail";
  #     ExecStart = "${pkgs.writeScript "gmi-pull" ''
  #       #!/usr/bin/env bash
  #       gmi pull
  #       notmuch new
  #     ''}";
  #   };
  # };
  # systemd.user.timers.gmi = {
  #   Timer = {
  #     OnCalendar = "*:0/5";
  #     Unit = "gmi.service";
  #   };
  #   Install.WantedBy = [ "timers.target" ];
  # };

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
    HOME_MANAGER_CONFIG = toString ./home.nix; # unused, but checked for existence
  };
}
