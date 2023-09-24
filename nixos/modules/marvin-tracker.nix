{ config, lib, pkgs, ... }:
let cfg = config.services.yorick.marvin-tracker; in
{
  options.services.yorick.marvin-tracker = with lib; {
    enable = mkEnableOption "Marvin Tracker server";
    host = mkOption {
      default = "::1";
      type = types.str;
    };
    port = mkOption {
      default = 4001;
      type = types.port;
    };
    package = mkOption {
      default = pkgs.marvin-tracker;
      type = types.package;
    };
    mqtt.topic = mkOption {
      default = "yorick/marvin/tracking";
      type = types.str;
    };
    mqtt.host = mkOption {
      default = "localhost";
      type = types.str;
    };
    secretFile = mkOption {
      type = types.path;
      default = "/dev/null";
    };
    api_hash = mkOption {
      type = types.str;
      default = "z6mzC2TGdVCRuFE+oCrwj1GCHyP6OzYcPKZDiO/yLdqpmChC6S7ijCEUSY5gtqhpXhtYeDRyBjNeVJ/0Se4jQQ==";
      description = "public key for the secret header value";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.marvin-tracker = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        Restart = "on-failure";
        ExecStart = "${cfg.package}/index.js";
        EnvironmentFile = cfg.secretFile;
      };
      environment = {
        HOST = cfg.host;
        PORT = toString cfg.port;
        TOPIC = cfg.mqtt.topic;
        API_HASH = cfg.api_hash;
      };
    };
  };
}
