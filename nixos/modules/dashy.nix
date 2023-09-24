{ config, lib, pkgs, ... }:
let cfg = config.services.dashy; in
{
  options.services.dashy = with lib; {
    enable = mkEnableOption "Dashy server";
    host = mkOption {
      default = "0.0.0.0";
      type = types.str;
    };
    port = mkOption {
      default = 4000;
      type = types.port;
    };
    package = mkOption {
      default = pkgs.dashy;
      type = types.package;
    };
    configFile = mkOption {
      type = types.path;
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.dashy = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        Restart = "on-failure";
        ExecStart = "${pkgs.nodejs}/bin/node ${cfg.package}/server.js";
        WorkingDirectory = "${cfg.package}";
        BindReadOnlyPaths = [ "/etc/dashy.yml" ];
      };
      environment.HOST = cfg.host;
      environment.PORT = toString cfg.port;
    };
    environment.etc."dashy.yml".source = cfg.configFile;
  };
}
