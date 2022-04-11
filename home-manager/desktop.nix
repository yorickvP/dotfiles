{ pkgs, options, ... }:
let
  bin = pkgs.callPackage /home/yorick/dotfiles/bin { };
  font = {
    __toString = self: "${self.name} ${self.size}";
    name = "DejaVu Sans Mono";
    size = "11";
  };
  fixed_slack = pkgs.slack.override {
    xdg-utils = pkgs.xdg-utils.overrideAttrs (o: {
      buildInputs = o.buildInputs ++ [ pkgs.makeWrapper ];
      postInstall = o.postInstall + ''
        wrapProgram "$out/bin/xdg-open" --unset GDK_BACKEND
      '';
    });
  };
in
{
  # TODO: waybar module from home-manager
  xdg.configFile."waybar/config" = {
    text = builtins.toJSON (builtins.fromTOML (builtins.readFile ./waybar.toml));
    onChange = "systemctl --user restart waybar";
  };
  programs.waybar = {
    enable = true;
    style = ./waybar.css;
    systemd.enable = true;
  };
  programs.mako.enable = true;
  services = {
    gpg-agent.extraConfig = ''
      pinentry-program ${pkgs.pinentry_gnome}/bin/pinentry-gnome3
    '';
  };
  wayland.windowManager.sway = {
    enable = true;
    config = {
      bars = [
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

          "XF86MonBrightnessUp" = exec light "light -T 1.1";
          "XF86MonBrightnessDown" = exec light "light -T 0.9";
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
        bg "/home/yorick/wp/beyond-4k-2560×1440.jpg" fill
      }
      output "BenQ Corporation BenQ GW2765 36H03689019" {
        position 2560 0
        bg "/home/yorick/wp/beyond-4k-2560×1440.jpg" fill
      }
      output "Sharp Corporation 0x144A 0x00000000" {
        bg "/home/yorick/wp/thorns__4k__by_kasperja-daqi5g7.jpg" fill
      }
      output "Unknown 0x1403 0x00000000" {
        bg "/home/yorick/wp/lawn_forest_mountains_144578_3840x2400.jpg" fill
      }
      output "eDP-1" {
        # disable
      }
      input "1267:12679:ELAN0672:00_04F3:3187_Touchpad" {
        natural_scroll enabled
        tap enabled
        dwt enabled
        # middle_emulation enabled
      }
      input '2:10:TPPS/2_Elan_TrackPoint' accel_profile flat
      input "1739:30383:DLL075B:01_06CB:76AF_Touchpad" {
        natural_scroll enabled
        tap enabled
        dwt enabled
        # middle_emulation enabled
      }
      input "1:1:AT_Translated_Set_2_keyboard" {
        xkb_options caps:escape
      }
      input "1133:16498:Logitech_MX_Anywhere_2" {
        left_handed enabled
      }
      input "1133:45087:MX_Anywhere_2_Mouse" {
        left_handed enabled
      }
      for_window [app_id="ala-fzf"] floating enable
      exec mako
      exec swayidle timeout 300 'swaymsg "output * dpms off"; swaylock' resume 'swaymsg "output * dpms on"' before-sleep 'swaylock'
    '';
  };

  # programs.firefox = {
  #   enable = true;
  #   package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
  #     forceWayland = true;
  #   };
  # };
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
    vanilla-dmz
    # arc-theme
    libnotify
    #rxvt_unicode-with-plugins
    pavucontrol
    light
    # dropbox # really?
    # xorg.xrdb
    siji fira-mono playerctl
    mosquitto
    #hs.arbtt

    gebaar-libinput
    grim
    eagle
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
    zoom-us
  ];
}
