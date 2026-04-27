{
  lib,
  pkgs,
  config,
  ...
}:
{
  services.fwupd.enable = true;
  programs.fish.enable = true;
  users.users.yorick = {
    extraGroups = [
      "input"
      "wireshark"
      "dialout"
      "video"
    ]
    ++ (lib.optional config.virtualisation.libvirtd.enable "libvirtd")
    ++ (lib.optional config.virtualisation.docker.enable "docker");
    shell = pkgs.fish;
  };
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
  };
  environment.systemPackages = with pkgs; [
    ghostscript
    yubikey-manager
    glib
    solaar
    v4l-utils
    attic-client
  ];
  environment.sessionVariables.XDG_DATA_DIRS = with pkgs; [
    "${gnome-themes-extra}/share"
    "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
    # emacs?
  ];
  nix.gc.automatic = lib.mkOverride 30 false;
  # fix glasgow, fomu, backlight
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="20b7", ATTRS{idProduct}=="9db1", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="5bf0", TAG+="uaccess"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  # git
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 1024000000;

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
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts # Micrsoft free fonts
      inconsolata # monospaced
      source-code-pro
      ubuntu-classic
      source-han-sans
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.noto
      nerd-fonts.symbols-only
      iosevka
      joypixels
      font-awesome
    ];
  };
  # spotify, castnow
  networking.firewall = {
    allowedTCPPorts = [
      55025
      57621
      5353
    ];
    allowedTCPPortRanges = [
      {
        from = 4100;
        to = 4105;
      }
    ];
    allowedUDPPorts = [
      55025
      57621
    ];
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
          lib.makeLibraryPath (
            with pkgs;
            [
              libxkbcommon
              libglvnd
              wayland
            ]
          )
        }
      '';
    };
  };
  services.pcscd.enable = true;
  programs.gdk-pixbuf.modulePackages = [ pkgs.webp-pixbuf-loader ];
  hardware.ledger.enable = true;

  i18n.extraLocaleSettings.LC_TIME = "nl_NL.UTF-8";

  programs.criu.enable = true;
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };
  # services.udev.extraHwdb = ''
  #   mouse:*:name:*MX * 3*:
  #     MOUSE_WHEEL_CLICK_ANGLE=1
  #     MOUSE_WHEEL_CLICK_COUNT=1
  #     MOUSE_WHEEL_CLICK_ANGLE_HORIZONTAL=26
  #     MOUSE_WHEEL_CLICK_COUNT_HORIZONTAL=14
  # '';
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      zlib
      libusb1
      libxcrypt-legacy
    ];
  };
  services.envfs.enable = true;

  fonts.fontconfig.subpixel.rgba = "rgb";
  # screen control
  hardware.i2c.enable = true;
  hardware.bluetooth.enable = true;
  services.nix-ci-puller.topics = [ "yorick/git/dotfiles/main/yorick-home" ];

  # allow gpg agent forwarding
  services.openssh.settings.StreamLocalBindUnlink = true;

  age.secrets.connect-idle = {
    file = ../../secrets/y-connect-idle.env.age;
    owner = "yorick";
  };
  age.secrets.marvin-tracker = {
    file = ../../secrets/marvin-tracker.env.age;
    owner = "yorick";
  };
}
