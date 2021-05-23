{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.arbtt;

in {

  options.services.arbtt = {
    enable = mkEnableOption "arbtt";

    package = mkOption { type = types.package; default = pkgs.haskellPackages.arbtt; };

  };

  config = mkIf cfg.enable {
    systemd.user.services.arbtt = {
      Unit = {
        Description = "arbtt";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = ''
          ${cfg.package}/bin/arbtt-capture
        '';
      };
    };

  };

}
