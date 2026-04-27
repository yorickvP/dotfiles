{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.nix-ci-puller;
in
{
  options.services.nix-ci-puller = {
    enable = lib.mkEnableOption "Nix CI store path puller via MQTT";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.y-nix-ci-puller.override { nix = config.nix.package; };
      defaultText = "pkgs.y-nix-ci-puller";
      description = "The y-nix-ci-puller package to use";
    };

    mqttBroker = lib.mkOption {
      type = lib.types.str;
      default = "frumar.vpn.yori.cc";
      description = "MQTT broker hostname";
    };

    mqttUser = lib.mkOption {
      type = lib.types.str;
      default = "ci-puller";
      description = "MQTT username";
    };

    mqttPasswordFile = lib.mkOption {
      type = lib.types.path;
      default = config.age.secrets.ci-puller-mqtt-env.path;
      defaultText = "config.age.secrets.ci-puller-mqtt-env.path";
      description = "Path to file containing MQTT_PASSWORD=...";
    };

    topics = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "yorick/git/dotfiles/main/${config.networking.hostName}" ];
      description = "MQTT topics to subscribe to";
    };

    allowedSSIDs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Allowed wifi SSIDs for fetching (empty = allow all)";
    };

    gcrootDir = lib.mkOption {
      type = lib.types.str;
      default = "/nix/var/nix/gcroots/ci-puller";
      description = "Directory for GC root symlinks";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    age.secrets.ci-puller-mqtt-env.file = ../../secrets/ci-puller-mqtt.env.age;

    systemd.services.nix-ci-puller = {
      description = "Nix CI Store Path Puller";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " (
          [
            "${cfg.package}/bin/y-nix-ci-puller"
          ]
          ++ cfg.topics
        );
        Restart = "on-failure";
        RestartSec = "30s";
        EnvironmentFile = cfg.mqttPasswordFile;
      };

      environment = {
        MQTT_BROKER = cfg.mqttBroker;
        MQTT_USER = cfg.mqttUser;
        GCROOT_DIR = cfg.gcrootDir;
      }
      // lib.optionalAttrs (cfg.allowedSSIDs != [ ]) {
        ALLOWED_SSIDS = lib.concatStringsSep "," cfg.allowedSSIDs;
      };

      path = [
        cfg.package
        config.nix.package
        pkgs.libnotify
        pkgs.systemd
        pkgs.iw
        pkgs.util-linux
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.gcrootDir} 0755 root root -"
    ];
  };
}
