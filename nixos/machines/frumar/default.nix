{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../roles/server.nix
    ../../roles/homeserver.nix
    ../../services/cache.nix
  ];

  system.stateVersion = "15.09";
  networking.hostId = "0702dbe9";
  systemd.network.networks."10-lan" = {
    name = "eno1";
    DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };

  services.postgresql.package = pkgs.postgresql_15;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = [ "frumar-new/userdata" ];

  networking.firewall = {
    interfaces.wg-y.allowedTCPPorts = [
      # victoriametrics, victorialogs
      8428
      9428
      # mqtt
      1883
    ];
    interfaces.wg-y.allowedUDPPorts = [ 1883 ];
    interfaces.eno1.allowedTCPPorts = [
      1883
      8554
    ];
    interfaces.eno1.allowedUDPPorts = [
      1883
      8554
    ];
  };
  programs.msmtp.enable = true;
  services.smartd.enable = true;

  age.secrets = {
    attic.file = ../../../secrets/attic.env.age;
    frigate-env.file = ../../../secrets/frigate.env;
    frumar-disk-encryption.file = ../../../secrets/frumar-disk-encryption.age;
    grafana.file = ../../../secrets/grafana.env.age;
    marvin-tracker.file = ../../../secrets/marvin-tracker.env.age;
    msmtp-mail-pass.file = ../../../secrets/frumar-mail-pass.age;
    oauth2-proxy.file = ../../../secrets/oauth2-proxy.age;
    yobot-telegram.file = ../../../secrets/yobot-telegram.age;
    zigbee2mqtt.file = ../../../secrets/zigbee2mqtt.env.age;
  };
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.age.secrets.grafana.path;
  systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = config.age.secrets.zigbee2mqtt.path;

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi;
    jrePackage = pkgs.jdk25_headless;
    mongodbPackage = pkgs.mongodb-7_0;
  };
  services.yorick.paperless = {
    enable = true;
    openFirewall = true;
    scanner_ip = "192.168.2.49";
  };
  services.nats = {
    enable = true;
    jetstream = true;
    settings = {
      mqtt.port = 1883;
      system_account = "SYS";
      accounts = builtins.fromTOML (builtins.readFile ./nats-accounts.toml);
    };
  };
  services.yorick.cache = {
    enable = true;
    vhost = "cache.yori.cc";
    nginx = {
      onlySSL = true;
      useACMEHost = "wildcard.yori.cc";
    };
    secretFile = config.age.secrets.attic.path;
  };
  services.yorick.marvin-tracker = {
    enable = true;
    secretFile = config.age.secrets.marvin-tracker.path;
  };
  services.immich.enable = true;
  programs.fish.enable = true;
  users.users.yorick.packages = with pkgs; [
    borgbackup
    bup
    fzf
    git-annex
    magic-wormhole
    python3
    ranger
    jq
    unzip
  ];
  age.secrets.nixbuildnet.file = ../../../secrets/frumar-nixbuildnet.age;
  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IPQoS throughput
      IdentityFile ${config.age.secrets.nixbuildnet.path}
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "x86_64-linux";
        maxJobs = 100;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
    ];
  };
  services.go2rtc = {
    enable = true;
    settings = {
      rtsp.listen = ":8554";
      api.origin = "*"; # allow WebSocket upgrades from HA frontend (home-assistant.yori.cc)
      # camera pushes RTSP into go2rtc, so no source URL here
      streams."28704e17f84b" = [ ];
      streams."28704e17f84b_sub" = [ ];
    };
  };
  services.frigate = {
    enable = true;
    hostname = "frigate.yori.cc";
    preCheckConfig = "export FRIGATE_MQTT_PASSWORD=dummy";
    settings = {
      mqtt = {
        enabled = true;
        host = "localhost";
        user = "frigate";
        password = "{FRIGATE_MQTT_PASSWORD}";
      };
      go2rtc.streams = config.services.go2rtc.settings.streams;
      detectors.coral = {
        type = "edgetpu";
        device = "usb";
      };
      objects.track = [
        "person"
        "cat"
        "bird"
      ];
      objects.filters.person.mask = "0.214,0.496,0.222,0.408,0.311,0.398,0.327,0.491";
      motion.contour_area = 25;
      record = {
        enabled = true;
        alerts.retain.days = 14;
      };
      ffmpeg.output_args.record = "preset-record-generic-audio-copy";
      cameras.garden = {
        live.height = 360;
        live.streams = {
          "HD" = "28704e17f84b";
          "SD" = "28704e17f84b_sub";
        };
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8554/28704e17f84b";
            input_args = "preset-rtsp-restream";
            roles = [ "record" ];
          }
          {
            path = "rtsp://127.0.0.1:8554/28704e17f84b_sub";
            input_args = "preset-rtsp-restream";
            roles = [
              "detect"
              "audio"
            ];
          }
        ];
      };
    };
  };
  fileSystems."/var/cache/frigate" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=4G"
      "mode=0750"
      "uid=frigate"
      "gid=frigate"
    ];
  };
  systemd.services.frigate.serviceConfig = {
    EnvironmentFile = config.age.secrets.frigate-env.path;
    CacheDirectory = lib.mkForce [
      "frigate"
      "frigate-models"
    ];
    ExecStartPre = lib.mkAfter [
      (pkgs.writeShellScript "frigate-link-model-cache" ''
        rm -rf /var/cache/frigate/model_cache
        ln -sfn /var/cache/frigate-models /var/cache/frigate/model_cache
      '')
    ];
  };
  services.disjoin = {
    enable = true;
    audioCodec = "opus";
    substreamChannel = "video3";
    substreamFps = 5;
    openFirewall = true;
  };
}
