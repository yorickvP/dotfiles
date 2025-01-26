{ lib, pkgs, config, ... }:
let
  cfg = config.services.wg-restarter;
in
{
  options.services.wg-restarter = {
    enable = lib.mkEnableOption "Gateway connectivity monitoring and WireGuard restart service";

    gateway = lib.mkOption {
      type = lib.types.str;
      example = "192.168.1.1";
      description = "Gateway IP address to monitor";
    };

    service = lib.mkOption {
      type = lib.types.str;
      default = "wireguard-wg-0";
      description = "Systemd service name to restart when gateway is unreachable";
    };

    interval = lib.mkOption {
      type = lib.types.int;
      default = 120;
      description = "Check interval in seconds";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wg-restarter;
      defaultText = "pkgs.wg-restarter";
      description = "The wg-restarter package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.wg-restarter = {
      description = "Gateway Connectivity Monitor";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/wg-restarter " +
          "-gateway ${cfg.gateway} " +
          "-service ${cfg.service} " +
          "-interval ${toString cfg.interval}";
        Restart = "on-failure";
        RestartSec = "30s";
      };
      path = [ cfg.package pkgs.fping pkgs.systemd ];
    };

  };
}
