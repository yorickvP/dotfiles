{
  lib,
  pkgs,
  options,
  ...
}:
let
  bin = pkgs.callPackage ../bin { };
  bg = {
    xps9360 = "/home/yorick/wp/thorns__4k__by_kasperja-daqi5g7.jpg fill";
    desktop = "/home/yorick/wp/leonid5-high.webp fill";
    x11carbon = "/home/yorick/wp/lawn_forest_mountains_144578_3840x2400.jpg fill";
    office = "/home/yorick/wp/fbm5e22acf8e1.png fill";
  };
  headphones = "80:99:E7:E4:01:78";
in
{
  systemd.user.services.waybar.Service.Environment = [
    "PATH=${
      lib.makeBinPath (
        with pkgs;
        [
          pavucontrol
          xdg-utils
          bin.y-cal-widget
          playerctl
          bluez
          gnugrep
          bash
          systemd
          chromium
          sway
        ]
      )
    }"
  ];
  programs.waybar = {
    enable = true;
    style = ./waybar.css;
    systemd.enable = true;
    settings.main = builtins.fromTOML (builtins.readFile ./waybar.toml);
  };
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 60 * 1000; # ms
      height = 200;
      "mode=do-not-disturb".invisible = 1;
    };
  };
  services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3;
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false; # looks for wallpapers
    config = {
      bars = [ ];
      gaps.inner = 5;
      modifier = "Mod4";
      window.hideEdgeBorders = "smart";
      fonts.names = [ "DejaVu Sans Mono" ];
      fonts.size = 11.0;
      window.border = 2;
      floating.modifier = "Mod4";
      focus.newWindow = "urgent";
      keybindings =
        with pkgs;
        (builtins.head (builtins.head options.wayland.windowManager.sway.config.type.getSubModules).imports)
        .options.keybindings.default
        // (
          let
            exec = pkg: cmd: "exec --no-startup-id ${pkg}/bin/${cmd}";
            mod = "Mod4";
          in
          {
            "${mod}+Shift+c" = "kill";
            "${mod}+j" = "focus left";
            "${mod}+k" = "focus right";
            "${mod}+d" = "layout toggle split";
            "${mod}+i" = "exec --no-startup-id bash /home/yorick/dotfiles/bin/invert.sh";
            #"${mod}+ctrl+l" = "exec --no-startup-id loginctl lock-session";
            "${mod}+ctrl+l" =
              "exec --no-startup-id \"playerctl -a pause; (bluetoothctl disconnect ${headphones} &) && sleep 1s && pkill -USR1 swayidle\"";
            "--locked ${mod}+ctrl+u" = "output * dpms on";
            "${mod}+Return" = "exec bash /home/yorick/dotfiles/bin/new-ghostty.sh";
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

            "XF86MonBrightnessUp" = exec light "light -T 1.1";
            "XF86MonBrightnessDown" = exec light "light -T 0.9";
            "ctrl+XF86MonBrightnessUp" = exec light "light -A 1";
            "ctrl+XF86MonBrightnessDown" = exec light "light -U 1";
            "XF86AudioLowerVolume" = exec alsa-utils "amixer set Master 1%-";
            "XF86AudioRaiseVolume" = exec alsa-utils "amixer set Master 1%+";
            "XF86AudioMute" = exec alsa-utils "amixer set Master toggle";
            "XF86AudioPause" = "exec playerctl pause";
            "XF86AudioPlay" = "exec playerctl play";
            "${mod}+Shift+s" = exec bin.screenshot_public "screenshot_public";
            "${mod}+Ctrl+Shift+s" = exec pkgs.sway-contrib.grimshot "grimshot --notify copy anything";
            "Print" = exec bin.screenshot_public "screenshot_public";
            "${mod}+Shift+t" = "exec --no-startup-id /home/yorick/dotfiles/bin/toggle_solarized.sh";
            "${mod}+p" = "exec /home/yorick/dotfiles/bin/ghostty-fzf-pass.sh";
            #"${mod}+p" = exec rofi-pass "rofi-pass";
            "${mod}+e" = exec pkgs.wldash "wldash start-or-kill";
            "${mod}+F1" = "exec --no-startup-id ddcutil -b 17 setvcp 10 - 5 --sleep-multiplier 0.0001";
            "${mod}+F2" = "exec --no-startup-id ddcutil -b 17 setvcp 10 + 5 --sleep-multiplier 0.0001";
          }
        );
      workspaceAutoBackAndForth = true;

      # xps9360
      input."1267:8400:ELAN_Touchscreen".map_to_output = "eDP-1";
      input."1267:12679:ELAN0672:00_04F3:3187_Touchpad" = {
        natural_scroll = "enabled";
        tap = "enabled";
        dwt = "enabled";
        drag_lock = "disabled";
      };
      output."Sharp Corporation 0x144A Unknown".bg = bg.xps9360;

      # desk
      output."HYC CO., LTD. DUAL-DVI Unknown" = {
        position = "0 0";
        bg = bg.desktop;
        max_render_time = "4";
      };
      output."HYC CO., LTD.  Unknown" = {
        position = "0 0";
        bg = bg.desktop;
        max_render_time = "4";
      };
      output."HYC CO., LTD. DUAL-DVI" = {
        position = "0 0";
        bg = bg.desktop;
      };
      output."BNQ BenQ GW2765 36H03689019" = {
        position = "2560 0";
        bg = bg.desktop;
        max_render_time = "4";
      };
      # office monitors
      output."Dell Inc. DELL U2725QE G98Y934" = {
        mode = "3840x2160@60.000Hz";
        scale = "1.5";
        position = "2560 0";
        bg = bg.office;
      };
      output."Dell Inc. DELL U2725QE FB8Y934" = {
        mode = "3840x2160@120.000Hz";
        scale = "1.5";
        position = "0 0";
        bg = bg.office;
      };

      # x11 carbon
      input."2:10:TPPS/2_Elan_TrackPoint".accel_profile = "flat";
      output."California Institute of Technology 0x1403".bg = bg.x11carbon;
      input."1739:30383:DLL075B:01_06CB:76AF_Touchpad" = {
        natural_scroll = "enabled";
        tap = "enabled";
        dwt = "enabled";
        drag_lock = "disabled";
      };

      # generic
      input."1:1:AT_Translated_Set_2_keyboard".xkb_options = "caps:escape";
      input."1133:16498:Logitech_MX_Anywhere_2".left_handed = "enabled";
      input."1133:16498:Logitech_MX_Anywhere_2".scroll_factor = "0.144";
      input."1133:45087:MX_Anywhere_2".left_handed = "enabled";
      input."1133:45087:MX_Anywhere_2".scroll_factor = "0.144";
      input."1133:45111:MX_Anywhere_3S".left_handed = "enabled";
      input."1133:45111:MX_Anywhere_3S".scroll_factor = "0.072";
      input."1133:45111:Logitech_MX_Anywhere_3S".left_handed = "enabled";
      input."1133:45111:Logitech_MX_Anywhere_3S".scroll_factor = "0.072";
      window.commands = [
        {
          criteria.app_id = "ala.fzf";
          command = "floating enable";
        }
        {
          criteria.app_id = "Waydroid";
          command = "floating enable";
        }
        # {
        #   criteria.app_id = "emacs";
        #   command = "opacity 0.95";
        # }
        {
          criteria.title = "Firefox — Sharing Indicator";
          command = "floating enable";
        }
      ];
      startup = [
        { command = "mako"; }
        {
          command = ''swayidle -w timeout 300 'swaymsg "output * dpms off"; swaylock -f' resume 'swaymsg "output * dpms on"' before-sleep 'swaylock -f' lock 'swaylock -f' unlock 'pkill -USR1 swaylock' idlehint 300'';
        }
        # todo: kanshi
      ];
    };
    systemd.enable = true;
    # fix pinentry-gnome3
    extraConfig = ''
      include /etc/sway/config.d/*
    '';
  };

  programs.firefox.enable = true;

  home.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
    MOZ_ENABLE_WAYLAND = "1";
    EDITOR = "emacsclient";
    #GDK_BACKEND = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_QPA_PLATFORM = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XDG_CURRENT_DESKTOP = "sway";
    NIXOS_OZONE_WL = "1";
  };
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    enable = true;
    gtk.enable = true;
    dotIcons.enable = true;
    sway.enable = true;
    size = 24;
  };
  systemd.user.services.wayland-push-to-talk-fix =
    let
      kbd = "/dev/input/by-id/usb-Kinesis_Advantage2_Keyboard_314159265359-if01-event-kbd";
    in
    {
      Unit.ConditionPathExists = kbd;
      Install.WantedBy = [ "graphical-session.target" ];
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wayland-push-to-talk-fix}/bin/wayland-push-to-talk-fix ${kbd} -k KEY_LEFTALT -n Alt_L";
        Restart = "on-failure";
      };
    };
  systemd.user.services.notify-codes = {
    Install.WantedBy = [ "graphical-session.target" ];
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.notify-codes}/bin/notify-codes";
      Restart = "on-failure";
      Environment = [
        "PATH=${
          lib.makeBinPath (
            with pkgs;
            [
              wl-clipboard
              libnotify
            ]
          )
        }"
      ];
    };
  };
  systemd.user.services.y-connect-idle = {
    Install.WantedBy = [ "graphical-session.target" ];
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.y-connect-idle}/bin/y-connect-idle";
      Restart = "on-failure";
      RestartMaxDelaySec = "10m";
      RestartSteps = 8;
      Environment = [
        "MQTT_BROKER=frumar.vpn.yori.cc"
        "MQTT_USER=iot"
        "MQTT_PASSWORD=asdf"
      ];
    };
  };
  # todo: use home-manager unit
  systemd.user.services.gmi = {
    Unit.ConditionPathExists = "/home/yorick/mail/account.gmail/.gmailieer.json";
    Service = {
      Environment = [
        "PATH=${
          lib.makeBinPath (
            with pkgs;
            [
              bash
              lieer
              notmuch
              afew
            ]
          )
        }"
      ];
      Type = "oneshot";
      ExecStart = "/usr/bin/env bash -c 'gmi pull && notmuch new'";
      WorkingDirectory = "/home/yorick/mail/account.gmail";
    };
  };
  systemd.user.timers.gmi = {
    Timer = {
      OnCalendar = "hourly";
      RandomizedDelaySec = "5min";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
  programs.obs-studio = rec {
    enable = true;
    plugins = [ (pkgs.obs-studio-plugins.wlrobs.override { obs-studio = package; }) ];
    package = pkgs.obs-studio.override { browserSupport = false; };
  };
  # systemd.user.services.kdeconnect-indicator.Unit.After = [ "waybar.service" ];
  home.packages = with pkgs; [
    gtk-engine-murrine
    hicolor-icon-theme
    libnotify
    light
    mosquitto
    pavucontrol
    playerctl
    vanilla-dmz

    libwebp
    gebaar-libinput
    grim
    element-desktop
    libreoffice
    slack
    slurp
    sway-contrib.grimshot
    swaybg
    swayidle
    swaylock
    waybar
    waypipe
    wl-clipboard
    wldash
    zoom-us
    bin.y-cal-widget
    obsidian
    thunderbird
    #xwaylandvideobridge
    easyeffects
    # bitwarden-desktop
    soco-cli # sonos speakers
    bubblewrap
    landrun
    claude-code
    llm-agents.ccusage
    ddcutil
    bluetui
  ];
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "writer.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
  };
  xdg.configFile."uv/uv.toml".source = (pkgs.formats.toml { }).generate "uv-config" {
    "link-mode" = "clone";
  };
}
