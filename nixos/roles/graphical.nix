let secrets = import <secrets>;
in { config, lib, pkgs, ... }: {
  imports = [ ./. ];
  options.yorick.support32bit = with lib;
    mkOption {
      type = types.bool;
      default = false;
    };
  config = {
    hardware.opengl = {
      enable = true;
      driSupport32Bit = config.yorick.support32bit;
    };
    users.users.yorick.extraGroups = [ "video" ];
    # fix backlight permissions
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    '';

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
        font-awesome
      ];
    };
    # spotify
    networking.firewall.allowedTCPPorts = [ 55025 57621 ];
    networking.firewall.allowedUDPPorts = [ 55025 57621 ];

    services.openssh.forwardX11 = true;

    programs.sway = {
      enable = true;
      extraSessionCommands = ''
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${
          lib.makeLibraryPath (with pkgs; [ libxkbcommon libglvnd wayland ])
        }
      '';
    };
  };
}
