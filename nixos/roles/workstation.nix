{ config, lib, pkgs, ... }:
{
  services.fwupd.enable = true;
  programs.fish.enable = true;
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
  nix.gc.automatic = lib.mkOverride 30 false;
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
    enable = false;
    enableTCPIP = true;
    package = pkgs.postgresql_11;
  };

  # git
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 1024000000;

  yorick.lumi-vpn.enable = false;
  yorick.lumi-cache.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # todo: support32bit?
    pulse.enable = true;
  };
  # bluetooth battery indicator
  hardware.bluetooth = {
    package = pkgs.bluez5-experimental;
    settings.General.Experimental = true;
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts # Micrsoft free fonts
      inconsolata # monospaced
      source-code-pro
      ubuntu_font_family # Ubuntu fonts
      source-han-sans
      (nerdfonts.override {
        fonts = [
          "DejaVuSansMono"
          "Noto"
          "NerdFontsSymbolsOnly"
        ];
      })
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
    kdeconnect.enable = true;
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
  services.xserver.gdk-pixbuf.modulePackages = [ pkgs.webp-pixbuf-loader ];
  hardware.ledger.enable = true;

  networking.wireguard.interfaces.wg-dk = {
    privateKeyFile =
      "/home/yorick/datakami/infra/keys/wg.yorick.key";
    ips = [ "10.100.0.4/32" ];
    peers = [{
      publicKey = "teCEYc4KWT6rGchNOp6sIFO0jmkhwTjv6reOzGscAm8=";
      endpoint = "dk-1.datakami.nl:51820";
      allowedIPs = [ "10.100.0.0/24" ];
      persistentKeepalive = 25;
    }];
  };
}
