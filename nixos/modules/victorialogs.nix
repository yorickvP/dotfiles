{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.victorialogs;
in
{
  options.services.victorialogs = {
    enable = mkEnableOption "VictoriaLogs service";

    package = mkOption {
      type = types.package;
      default = pkgs.victorialogs;
      description = "VictoriaLogs package to use";
    };

    extraOptions = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Extra options to pass to VictoriaLogs";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.victorialogs = {
      description = "VictoriaLogs Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "victorialogs";
        WorkingDirectory = "/var/lib/victorialogs";
        ExecStart = lib.escapeShellArgs (
          [ "${cfg.package}/bin/victoria-logs" ]
          ++ (lib.mapAttrsToList (name: value: "-${name}=${value}") cfg.extraOptions)
        );
        Restart = "on-failure";
        RestartSec = 1;
        LimitNOFILE = 1048576;
        # Hardening
        DeviceAllow = [ "/dev/null rw" ];
        DevicePolicy = "strict";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "full";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
      };
      postStart =
        let
          bindAddr =
            ("127.0.0.1") + cfg.listenAddress;
        in
        lib.mkBefore ''
          until ${lib.getBin pkgs.curl}/bin/curl -s -o /dev/null http://127.0.0.1:9428/ping; do
            sleep 1;
          done
        '';
    };

  };
}
