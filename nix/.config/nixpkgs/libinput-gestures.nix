{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.libinput-gestures;

in {

  options.services.libinput-gestures = {
    enable = mkEnableOption "libinput-gestures";

    package = mkOption { type = types.package; default = pkgs.libinput-gestures; };

  };

  config = mkIf cfg.enable {
    systemd.user.services.libinput-gestures = {
      Unit = {
        Description = "libinput-gestures";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = ''
          ${pkgs.libinput-gestures}/bin/libinput-gestures
        '';
      };
    };

  };

}
