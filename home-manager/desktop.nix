{ pkgs, options, ... }:
let
  bin = pkgs.callPackage /home/yorick/dotfiles/bin { };
  fixed_slack = pkgs.slack.override {
    xdg-utils = pkgs.xdg-utils.overrideAttrs (o: {
      buildInputs = o.buildInputs ++ [ pkgs.makeWrapper ];
      postInstall = o.postInstall + ''
        wrapProgram "$out/bin/xdg-open" --unset GDK_BACKEND
      '';
    });
  };
  bg = {
    xps9360 = "/home/yorick/wp/thorns__4k__by_kasperja-daqi5g7.jpg fill";
    desktop = "/home/yorick/wp/beyond-4k-2560×1440.jpg fill";
    x11carbon = "/home/yorick/wp/lawn_forest_mountains_144578_3840x2400.jpg fill";
  };
in {
  # TODO: waybar module from home-manager
  xdg.configFile."waybar/config" = {
    text =
      builtins.toJSON (builtins.fromTOML (builtins.readFile ./waybar.toml));
    onChange = "systemctl --user restart waybar";
  };
  programs.waybar = {
    enable = true;
    style = ./waybar.css;
    systemd.enable = true;
  };
  programs.mako.enable = true;
  programs.mako.defaultTimeout = 60 * 1000; # ms
  # todo broken
  # services.gpg-agent.pinentryFlavor = "gnome3";
  wayland.windowManager.sway = {
    enable = true;
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
            "exec --no-startup-id \"playerctl -a pause; (bluetoothctl disconnect 94:DB:56:79:7D:86 &) && sleep 1s && pkill -USR1 swayidle\"";
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

          "XF86MonBrightnessUp" = exec light "light -T 1.1";
          "XF86MonBrightnessDown" = exec light "light -T 0.9";
          "ctrl+XF86MonBrightnessUp" = exec light "light -A 1";
          "ctrl+XF86MonBrightnessDown" = exec light "light -U 1";
          "XF86AudioLowerVolume" = exec alsaUtils "amixer set Master 1%-";
          "XF86AudioRaiseVolume" = exec alsaUtils "amixer set Master 1%+";
          "XF86AudioMute" = exec alsaUtils "amixer set Master toggle";
          "XF86AudioPause" = "exec playerctl pause";
          "XF86AudioPlay" = "exec playerctl play";
          "${mod}+Shift+s" = exec bin.screenshot_public "screenshot_public >> ~/screenshot-public.log";
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
      workspaceAutoBackAndForth = true;

      # xps9360
      input."1267:8400:ELAN_Touchscreen".map_to_output = "eDP-1";
      input."1267:12679:ELAN0672:00_04F3:3187_Touchpad" = {
        natural_scroll = "enabled";
        tap = "enabled";
        dwt = "enabled";
      };
      output."Sharp Corporation 0x144A 0x00000000".bg = bg.xps9360;

      # desk
      output."Unknown  0x00000000" = {
        position = "0 0";
        bg = bg.desktop;
      };
      output."BenQ Corporation BenQ GW2765 36H03689019" = {
        position = "2560 0";
        bg = bg.desktop;
      };

      # x11 carbon
      input."2:10:TPPS/2_Elan_TrackPoint".accel_profile = "flat";
      output."Unknown 0x1403 0x00000000".bg = bg.x11carbon;
      input."1739:30383:DLL075B:01_06CB:76AF_Touchpad" = {
        natural_scroll = "enabled";
        tap = "enabled";
        dwt = "enabled";
      };

      # generic
      input."1:1:AT_Translated_Set_2_keyboard".xkb_options = "caps:escape";
      input."1133:16498:Logitech_MX_Anywhere_2".left_handed = "enabled";
      input."1133:45087:MX_Anywhere_2_Mouse".left_handed = "enabled";
      window.commands = [
        {
          criteria.app_id = "ala-fzf";
          command = "floating enable";
        }
        {
          criteria.app_id = "emacs";
          command = "opacity 0.95";
        }
      ];
      startup = [
        { command = "mako"; }
        {
          command = ''
            swayidle timeout 300 'swaymsg "output * dpms off"; swaylock' resume 'swaymsg "output * dpms on"' before-sleep 'swaylock' '';
        }
      ];
    };
    systemdIntegration = true;
  };

  programs.firefox = {
    # TODO: back to mozilla
    enable = true;
    package = pkgs.wrapFirefox pkgs.latest.firefox-bin.unwrapped {
      forceWayland = true;
      applicationName = "firefox";
    };
  };
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
  home.packages = with pkgs; [
    gtk-engine-murrine
    hicolor-icon-theme
    libnotify
    light
    mosquitto
    pavucontrol
    playerctl
    vanilla-dmz

    gebaar-libinput
    grim
    libreoffice
    obs-studio
    obs-wlrobs
    fixed_slack
    slurp
    swaybg
    swayidle
    swaylock
    waybar
    waypipe
    wl-clipboard
    wldash
    # zoom-us
    bin.y-cal-widget
  ];
}
