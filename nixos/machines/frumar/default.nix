{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../roles/server.nix
    ../../roles/homeserver.nix
    ../../services/cache.nix
    ../../services/backup.nix
  ];

  services.borgbackup.jobs.backup = {
    preHook = ''
      /run/current-system/sw/bin/zfs destroy ssdpool/root/var@borgbackup || true
      /run/current-system/sw/bin/zfs snapshot ssdpool/root/var@borgbackup
      sleep 5s
      ls /var/.zfs/snapshot/borgbackup > /dev/null
    '';
    postCreate = ''
      /run/current-system/sw/bin/zfs destroy ssdpool/root/var@borgbackup
    '';
    paths = [
      "/var/.zfs/snapshot/borgbackup/lib/hass"
      "/var/.zfs/snapshot/borgbackup/lib/paperless"
      "/var/.zfs/snapshot/borgbackup/lib/redis-paperless"
      "/var/.zfs/snapshot/borgbackup/lib/zigbee2mqtt"
    ];
  };
  users.users.znapzend-blackadder = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWwtQA8qAW24b9suTOdkHpQktWRiipoIQUXPnoxm2NHJpVEI24q6cSGsEjYoEs4Vac2bJ7Q93CASVm/qOSm46AMrpURdN2F6oClA/zKHUsZ9MGBkUXvm+HnspE6CpiGFCPtZyK9FpGm2Flwh/U0fd9txVuuNElERgXMY0GDodM/n4JzP6/9yk1F8WLkkhBHgQmqo2gzbEVtYjfpSQ/FyjcShlip0/EoPqhGM7K/WiaGLkbmtXQi5dFWwFwTzLA6NRsGGW2ag12RzR3ok9uwGIVW6Po8Z/XpwFetQTVl8Sfcn3PWQKKtzFzXmFnfwvgTj4f3EDnQNUDgrg8eIZV4B5QGml3CwwhWwup31kmnha7q+soottzMnUTqopa7RY6bcoMZsMpp0/LqyG5jCyFo7sH3E46YwX6xnB98dlP66DLCVvRBIRy/pxajC6XAIFFnfs1W3oDX17Tq4IqUF42gQEdVcYQ95tb/llrT/k1lEr1YuO/Rspwc1BK/e/6WvPR9KM= root@blackadder"
    ];
    isSystemUser = true;
    group = "znapzend-blackadder";
    useDefaultShell = true;
  };
  users.groups.znapzend-blackadder = { };
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
    interfaces.eno1.allowedTCPPorts = [ 1883 ];
    interfaces.eno1.allowedUDPPorts = [ 1883 ];
  };
  services.znapzend = {
    enable = true;
    zetup = {
      "frumar-new/userdata" = {
        plan = "1w=>6h,1m=>1w,1y=>1m,2y=>6m,50y=>1y";
      };
      "frumar-new/plexmedia" = {
        plan = "1w=>6h,1m=>1w,1y=>1m,2y=>6m,50y=>1y";
      };
      "ssdpool/root" = {
        plan = "2d=>1d";
      };
      "ssdpool/root/var" = {
        plan = "1w=>1d";
        destinations.frumar-new = {
          dataset = "frumar-new/backup/ssdpool-root-var";
          plan = "1w=>1d,1m=>1w,1y=>1m,10y=>6m,50y=>1y";
        };
      };
    };
  };

  programs.msmtp.enable = true;
  services.smartd.enable = true;

  age.secrets = {
    attic.file = ../../../secrets/attic.env.age;
    frumar-disk-encryption.file = ../../../secrets/frumar-disk-encryption.age;
    grafana.file = ../../../secrets/grafana.env.age;
    marvin-tracker.file = ../../../secrets/marvin-tracker.env.age;
    msmtp-mail-pass.file = ../../../secrets/frumar-mail-pass.age;
    oauth2-proxy.file = ../../../secrets/oauth2-proxy.age;
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
    unifiPackage = pkgs.pkgs-unstable.unifi;
    mongodbPackage = pkgs.mongodb-7_0;
  };
  services.victoriametrics = {
    enable = true;
    retentionPeriod = "1y";
  };
  services.yorick.paperless = {
    enable = true;
    openFirewall = true;
    scanner_ip = "192.168.2.49";
  };
  services.grafana = {
    enable = true;
    settings = {
      server.domain = "grafana.yori.cc";
      server.root_url = "https://grafana.yori.cc/";
      auth.oauth_allow_insecure_email_lookup = true;
      "auth.basic".enabled = false;
      "auth.google" = {
        enabled = true;
        allow_sign_up = false;
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "Pocket ID";
        icon = "https://pocket-id.yori.cc/api/application-images/logo";
        auth_url = "https://pocket-id.yori.cc/authorize";
        token_url = "https://pocket-id.yori.cc/api/oidc/token";
        allow_sign_up = true;
        use_pkce = true;
        # email_attribute_name = "email:primary";
        scopes = [
          "openid"
          "email"
          "profile"
        ];
        auth_style = "AutoDetect";
      };
      auth.disable_login_form = true;
    };
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
  services.victorialogs = {
    enable = true;
    extraOptions = [
      "-journald.streamFields=_HOSTNAME,_SYSTEMD_SLICE,_SYSTEMD_UNIT,SYSLOG_IDENTIFIER"
      "-memory.allowedPercent=10"
      "-retentionPeriod=14d"
      "-retention.maxDiskSpaceUsageBytes=10GiB"
    ];
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
}
