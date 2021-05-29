{ lib, config, options, pkgs, ... }:
let
  bin = pkgs.callPackage /home/yorick/dotfiles/bin { };
  dpi = 109;
  font = {
    __toString = self: "${self.name} ${self.size}";
    name = "DejaVu Sans Mono";
    size = "11";
  };
  y-firefox = pkgs.wrapFirefox pkgs.latest.firefox-beta-bin.unwrapped {
    forceWayland = true;
    browserName = "firefox";
  };
in {
  imports = [ ./arbtt.nix ./libinput-gestures.nix ];
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
          interleave
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
      matchBlocks = rec {
        "pub.yori.cc" = {
          user = "public";
          identityFile = "~/.ssh/id_rsa_pub";
          identitiesOnly = true;
        };
        phassa = {
          hostname = "karpenoktem.nl";
          port = 33933;
        };
        "jupiter.serokell.io" = jupiter;
        jupiter = {
          hostname = "jupiter.serokell.io";
          port = 17788;
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
        styx = {
          hostname = "10.110.0.1";
          user = "yorick.van.pelt";
          port = 2233;
        };
        "*.lumi.guide" = { user = "yorick.van.pelt"; };
        nyx = {
          hostname = "nyx.lumi.guide";
          user = "yorick.van.pelt";
          port = 2233;
        };
        zeus = {
          hostname = "zeus.lumi.guide";
          user = "yorick.van.pelt";
          port = 2233;
        };
        ponos = {
          hostname = "ponos.lumi.guide";
          user = "yorick.van.pelt";
          port = 2233;
        };
        medusa = {
          hostname = "lumi.guide";
          user = "yorick.van.pelt";
          port = 2233;
        };
        # signs
        "10.108.0.*" = {
          user = "yorick.van.pelt";
          port = 4222;
          # verified by wireguard key
          extraOptions.StrictHostKeyChecking = "no";
        };
        "10.109.0.*" = {
          user = "yorick.van.pelt";
          # verified by wireguard key
          extraOptions.StrictHostKeyChecking = "no";
        };
        "10.110.0.*" = {
          port = 2233;
          user = "yorick.van.pelt";
          # verified by wireguard key
          extraOptions.StrictHostKeyChecking = "no";
        };
        "10.111.0.*" = {
          user = "yorick.van.pelt";
          # verified by wireguard key
          extraOptions.StrictHostKeyChecking = "no";
        };
        "192.168.42.*" = {
          user = "yorick.van.pelt";
          #proxyJump = "athena";
        };
        # "192.168.178.*" = {
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
        function fuck -d "Correct your previous console command"
                 set -l fucked_up_command $history[1]
                 env TF_SHELL=fish TF_ALIAS=fuck PYTHONIOENCODING=utf-8 thefuck $fucked_up_command THEFUCK_ARGUMENT_PLACEHOLDER $argv | read -l unfucked_command
                 if [ "$unfucked_command" != "" ]
                     eval $unfucked_command
                     builtin history delete --exact --case-sensitive -- $fucked_up_command
                     builtin history merge ^ /dev/null
                 end
        end
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
                #eval $(thefuck --alias)
                    function fuck () {
                        TF_PYTHONIOENCODING=$PYTHONIOENCODING;
                        export TF_SHELL=bash;
                        export TF_ALIAS=fuck;
                        export TF_SHELL_ALIASES=$(alias);
                        export TF_HISTORY=$(fc -ln -10);
                        export PYTHONIOENCODING=utf-8;
                        TF_CMD=$(
                            thefuck THEFUCK_ARGUMENT_PLACEHOLDER $@
                        ) && eval $TF_CMD;
                        unset TF_HISTORY;
                        export PYTHONIOENCODING=$TF_PYTHONIOENCODING;
                        history -s $TF_CMD;
                    }
        # This script was automatically generated by the broot function
        # More information can be found in https://github.com/Canop/broot
        # This function starts broot and executes the command
        # it produces, if any.
        # It's needed because some shell commands, like `cd`,
        # have no useful effect if executed in a subshell.
        function br {
            f=$(mktemp)
            (
        	set +e
        	broot --outcmd "$f" "$@"
        	code=$?
        	if [ "$code" != 0 ]; then
        	    rm -f "$f"
        	    exit "$code"
        	fi
            )
            code=$?
            if [ "$code" != 0 ]; then
        	return "$code"
            fi
            d=$(<"$f")
            rm -f "$f"
            eval "$d"
        }
        eval "$(starship init bash)"
              '';
    };
  };
  xresources.properties = {
    "*font" = "xft:${font.name}:size=${font.size}:antialias=true:hinting=true";
    "rofi.font" = toString font;
    "Emacs.font" = "${font.name}-${font.size}";

    "Xft.dpi" = dpi;
    "*dpi" = dpi;
  };
  # xresources.extraConfig = builtins.readFile (
  #   pkgs.fetchFromGitHub {
  #     owner = "solarized";
  #     repo = "xresources";
  #     rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
  #     sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
  #   } + "/Xresources.dark");
  home.file.".emacs.d/init.el" = {
    source = (toString /home/yorick/dotfiles/emacs/.emacs.d/init.el);
  };
  xdg.configFile."streamlink/config".text = ''
    player = mpv --cache 2048
    default-stream = best
  '';
  xdg.configFile."waybar" = {
    source = ./waybar;
    recursive = true;
    onChange = "systemctl --user restart waybar";
  };
  programs.mako.enable = true;
  services = {
    lorri.enable = true;
    #arbtt.enable = true;
    libinput-gestures.enable = false;
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      extraConfig = ''
        pinentry-program ${pkgs.pinentry_gnome}/bin/pinentry-gnome3
      '';
    };
    # redshift = {
    #   enable = false;
    #   latitude = "51.8";
    #   longitude = "5.8";
    #   temperature = {
    #     day = 6500;
    #     night = 5500;
    #   };
    # };
  };
  wayland.windowManager.sway = {
    enable = true;
    #package = pkgs.i3-gaps;
    config = {
      bars = [
        #{ position = "top"; command = "swaybar"; statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs /home/yorick/dotfiles/i3/status.toml"; }
      ];
      gaps.inner = 5;
      modifier = "Mod4";
      window.hideEdgeBorders = "smart";
      fonts = [ (toString font) ];
      window.border = 2;
      floating.modifier = "Mod4";
      keybindings = with pkgs;
        (builtins.head (builtins.head
          options.wayland.windowManager.sway.config.type.getSubModules).imports).options.keybindings.default
        // (let
          exec = pkg: cmd: "exec --no-startup-id ${pkg}/bin/${cmd}";
          mod = "Mod4";
        in {
          "${mod}+Shift+c" = "kill";
          "${mod}+j" = "focus left";
          "${mod}+k" = "focus right";
          "${mod}+d" = "layout toggle split";
          "${mod}+i" =
            "exec --no-startup-id bash /home/yorick/dotfiles/bin/invert.sh";
          #"${mod}+ctrl+l" = "exec --no-startup-id loginctl lock-session";
          "${mod}+ctrl+l" =
            "exec --no-startup-id sleep 1s && pkill -USR1 swayidle";
          "${mod}+Return" = "exec alacritty";
          "${mod}+Escape" = "workspace back_and_forth";
          "${mod}+0" = "workspace 10";
          "${mod}+Shift+0" = "move container to workspace 10";
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Right" = "move right";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Ctrl+Right" = "move workspace to output right";
          "${mod}+Ctrl+Left" = "move workspace to output left";
          "${mod}+Ctrl+Up" = "move workspace to output up";
          "${mod}+Ctrl+Down" = "move workspace to output down";

          "XF86MonBrightnessUp" = exec light "light -A 5";
          "XF86MonBrightnessDown" = exec light "light -U 5";
          "ctrl+XF86MonBrightnessUp" = exec light "light -A 1";
          "ctrl+XF86MonBrightnessDown" = exec light "light -U 1";
          "XF86AudioLowerVolume" = exec alsaUtils "amixer set Master 1%-";
          "XF86AudioRaiseVolume" = exec alsaUtils "amixer set Master 1%+";
          "XF86AudioMute" = exec alsaUtils "amixer set Master toggle";
          "${mod}+Shift+s" = exec bin.screenshot_public "screenshot_public";
          "Print" = exec bin.screenshot_public "screenshot_public";
          "${mod}+Shift+t" =
            "exec --no-startup-id /home/yorick/dotfiles/bin/toggle_solarized.sh";
          "--locked ${mod}+x" = "exec /home/yorick/dotfiles/bin/docked.sh";
          "${mod}+p" = "exec /home/yorick/dotfiles/bin/ala-fzf-pass.sh";
          #"${mod}+p" = exec rofi-pass "rofi-pass";
          "${mod}+e" = exec pkgs.wldash "wldash start-or-kill";
          "--locked ${mod}+bracketleft" =
            "exec --no-startup-id /home/yorick/dotfiles/bin/sunplate.sh 0";
          "--locked ${mod}+bracketright" =
            "exec --no-startup-id /home/yorick/dotfiles/bin/sunplate.sh 1";
        });
    };
    systemdIntegration = true;
    extraConfig = ''
      workspace_auto_back_and_forth yes
      input "1267:8400:ELAN_Touchscreen" {
        map_to_output eDP-1
      }
      output "Unknown  0x00000000" {
        position 0 0
        bg "/home/yorick/Downloads/wallpapers/beyond-4k-2560×1440.jpg" fill
      }
      output "BenQ Corporation BenQ GW2765 36H03689019" {
        position 2560 0
        bg "/home/yorick/Downloads/wallpapers/beyond-4k-2560×1440.jpg" fill
      }
      output "eDP-1" {
        # disable
      }
      input "1739:30383:DLL075B:01_06CB:76AF_Touchpad" {
        natural_scroll enabled
        tap enabled
        dwt enabled
        # middle_emulation enabled
      }
      input "1:1:AT_Translated_Set_2_keyboard" {
        xkb_options caps:escape
      }
      for_window [title="TelegramDesktop"] fullscreen enable
      for_window [app_id="ala-fzf"] floating enable
      exec mako
      exec swayidle timeout 300 'swaymsg "output * dpms off"; swaylock' resume 'swaymsg "output * dpms on"' before-sleep 'swaylock'
    '';
  };
  xsession.initExtra = "xrandr --dpi ${toString dpi}";
  home.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
    MOZ_ENABLE_WAYLAND = "1";
    EDITOR = "emacsclient";
    #GDK_BACKEND = "wayland";
    TERMINAL = "alacritty";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_QPA_PLATFORM = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_PATH = "${pkgs.gnome3.adwaita-icon-theme}/share/icons";
    XDG_CURRENT_DESKTOP = "sway";
  };
  home.packages = with pkgs.envs;
    [ apps code de games pdf media misc scripts coins js ] ++ (with pkgs; [
      github-cli
      libreoffice
      nix-tree
      virt-manager
      watchman
      gnome3.gcr.out # alacritty
      waybar
      slurp
      grim
      wl-clipboard
      wldash
      gebaar-libinput
      notmuch
      gmailieer
      afew
      swaybg
      swayidle
      swaylock
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
      slack
      smartmontools
      vim
      waypipe
      xdg_utils
      nix-top
      nix-diff
      ltrace
      asciinema
      cargo
      minecraft
      unzip
      exa
      obs-studio-dmabuf
      obs-wlrobs
      zoom-us
      cachix
      eagle
      y-firefox
    ]); # qtwayland
  # programs.firefox = {
  #   enable = true;
  #   package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
  #     forceWayland = true;
  #   };
  # };
  systemd.user.services.waybar = {
    Unit = {
      Description = "waybar";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };

    Service = {
      ExecStart = ''
        ${pkgs.waybar}/bin/waybar
      '';
    };
  };
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
  systemd.user.services.gebaard = {
    Unit = {
      Description = "gebaard";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };

    Service = {
      ExecStart = ''
        ${pkgs.gebaar-libinput}/bin/gebaard
      '';
    };
  };

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
}
