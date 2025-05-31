{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.play-nijmegen-calendar;
  localesWithDutch = pkgs.glibcLocales.override {
    allLocales = false;
    locales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "nl_NL.UTF-8/UTF-8"
    ];
  };
in
{
  options.services.play-nijmegen-calendar = {
    enable = mkEnableOption "Play Nijmegen Calendar generator";

    user = mkOption {
      type = types.str;
      default = "play-nijmegen-calendar";
      description = "User account under which the service runs.";
    };

    group = mkOption {
      type = types.str;
      default = "nginx";
      description = "Group under which the service runs (should be readable by nginx).";
    };

    interval = mkOption {
      type = types.str;
      default = "daily";
      description = "How often to run the calendar generator.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = "/var/lib/play-nijmegen-calendar";
    };

    systemd.services.nginx.serviceConfig = {
      BindReadOnlyPaths = [ "-/var/lib/play-nijmegen-calendar" ];
    };
    systemd.services.play-nijmegen-calendar = {
      description = "Play Nijmegen Calendar Generator";
      after = [ "network.target" ];
      environment.LOCALE_ARCHIVE = "${localesWithDutch}/lib/locale/locale-archive";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.play-nijmegen-calendar}/bin/play-nijmegen-calendar";
        WorkingDirectory = "/var/lib/play-nijmegen-calendar";
        StateDirectory = "play-nijmegen-calendar";
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };

    systemd.timers.play-nijmegen-calendar = {
      wantedBy = [ "timers.target" ];
      partOf = [ "play-nijmegen-calendar.service" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = 60 * 30;
      };
    };
  };
}
