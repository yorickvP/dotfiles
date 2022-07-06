{ config, lib, pkgs, ... }:
{
  services.fwupd.enable = true;
  users.users.yorick = {
    extraGroups = [ "input" "wireshark" "dialout" "video" "libvirtd" ];
    shell = pkgs.fish;
  };
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint cups-dymo ];
  };
  environment.systemPackages = with pkgs; [
    ghostscript yubikey-manager glib
  ];
  environment.sessionVariables.XDG_DATA_DIRS = with pkgs; [
    "${gnome-themes-extra}/share"
    "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
    # emacs?
  ];
  nix = {
    gc.automatic = pkgs.lib.mkOverride 30 false;
    settings.substituters = [
      "https://cache.nixos.org"
      #"s3://yori-nix?endpoint=s3.eu-central-003.backblazeb2.com&profile=backblaze-read"
      #"https://nixpkgs-wayland.cachix.org"
    ];
    settings.trusted-public-keys = [
      #"nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "yorick:Pmd0gyrTvVdzpQyb/raHJKdoOag8RLaj434qBgMm4I0="
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
  };
  virtualisation.libvirtd.enable = true;
  # fix glasgow, fomu, backlight
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="20b7", ATTRS{idProduct}=="9db1", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="5bf0", TAG+="uaccess"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  # picoscope
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/95-pico.rules" ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0ce9", TAG+="uaccess"
    '')
  ];

  # development
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_10;
  };

  # git
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 1024000000;

  yorick.lumi-vpn.enable = true;
  yorick.lumi-cache.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # todo: support32bit?
    pulse.enable = true;
    media-session.config.bluez-monitor.rules = [
      {
        # Matches all cards
        matches = [{ "device.name" = "~bluez_card.*"; }];
        actions = {
          "update-props" = {
            "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
            # mSBC is not expected to work on all headset + adapter combinations.
            "bluez5.msbc-support" = true;
            # SBC-XQ is not expected to work on all headset + adapter combinations.
            "bluez5.sbc-xq-support" = true;
          };
        };
      }
      {
        matches = [
          # Matches all sources
          {
            "node.name" = "~bluez_input.*";
          }
          # Matches all outputs
          { "node.name" = "~bluez_output.*"; }
        ];
        actions = { "node.pause-on-idle" = false; };
      }
    ];
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr xdg-desktop-portal-gtk ];
    gtkUsePortal = true;
  };
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts # Micrsoft free fonts
      inconsolata # monospaced
      source-code-pro
      ubuntu_font_family # Ubuntu fonts
      source-han-sans-japanese
      iosevka
      emojione
      font-awesome
    ];
  };
  # spotify, castnow
  networking.firewall = {
    allowedTCPPorts = [ 55025 57621 5353 ];
    allowedTCPPortRanges = [ { from = 4100; to = 4105; } ];
    allowedUDPPorts = [ 55025 57621 ];
  };

  programs = {
    dconf.enable = true;
    noisetorch.enable = true;
    wireshark.enable = true;
    sway = {
      enable = true;
      extraSessionCommands = ''
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${
          lib.makeLibraryPath (with pkgs; [ libxkbcommon libglvnd wayland ])
        }
      '';
    };
  };
  services.pcscd.enable = true;
}
