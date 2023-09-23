{ config, pkgs, lib, ... }: {
  imports = [
    ./fractal.nix
    ../../roles/server.nix
    ../../roles/homeserver.nix
    ./paperless.nix
    ./torrent.nix
  ];

  system.stateVersion = "15.09";
  networking.hostId = "0702dbe9";
  nixpkgs.overlays = [ (self: super: {
    openjdk8-bootstrap = super.openjdk8-bootstrap.override {
      gtkSupport = false;
    };
  }) ];

  systemd.tmpfiles.rules = lib.mkAfter [
    "d /var/lib/acme.sh/selfsign 0700 nginx nginx"
  ];
  systemd.services."yori-selfsigned-ca" = {
    description = "Generate self-signed fallback";
    path = with pkgs; [ minica ];
    unitConfig = {
      ConditionPathExists = "!/var/lib/acme.sh/selfsign/selfsigned.local/key.pem";
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      User = "nginx";
      Group = "nginx";
      UMask = "0077";
      Type = "oneshot";
      PrivateTmp = true;
      WorkingDirectory = "/var/lib/acme.sh/selfsign";
    };
    script = "minica --domains selfsigned.local";
  };
  systemd.services.nginx = {
    requires = [ "yori-selfsigned-ca.service" ];
    after = [ "yori-selfsigned-ca.service" ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."unifi.yori.cc" = {
      onlySSL = true;
      useACMEHost = "wildcard.yori.cc";
      locations."/" = {
        proxyPass = "https://[::1]:8443";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_ssl_verify off;
          proxy_ssl_session_reuse on;
        '';
      };
    };
    virtualHosts."home-assistant.yori.cc" = {
      onlySSL = true;
      useACMEHost = "wildcard.yori.cc";
      locations."/" = {
        proxyPass = "http://[::1]:8123";
        proxyWebsockets = true;
      };
    };
    virtualHosts."frumar.yori.cc" = {
      enableACME = lib.mkForce false;
      sslCertificate = "/var/lib/acme.sh/selfsign/selfsigned.local/cert.pem";
      sslCertificateKey = "/var/lib/acme.sh/selfsign/selfsigned.local/key.pem";
    };
  };
  boot.supportedFilesystems = [ "zfs" ];
  services.yorick.torrent-vpn = {
    enable = true;
    name = "mullvad-nl4";
    namespace = "torrent";
  };
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.plex.after = [ "data-plexmedia.mount" ];
  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
  services.unifi = {
    enable = true;
    openFirewall = true;
    jrePackage = pkgs.jre8_headless;
    unifiPackage = pkgs.unifiStable;
  };
  services.victoriametrics = {
    enable = true;
    retentionPeriod = 12;
  };
  services.prometheus = {
    enable = true;
    extraFlags = [ "--web.enable-admin-api" ];
    # victoriametrics
    remoteWrite = [{ url = "http://127.0.0.1:8428/api/v1/write"; }];
    scrapeConfigs = [
      # {
      #   job_name = "smartmeter";
      #   # prometheus doesn't support mdns :thinking_face:
      #   static_configs = [{ targets = [ "192.168.178.30" ]; }];
      #   scrape_interval = "10s";
      # }
      {
        job_name = "node";
        static_configs = [{ targets = [ "localhost:9100" ]; }];
        # } {
        #   job_name = "unifi";
        #   static_configs = [ { targets = [ "localhost:9130" ]; } ];
      }
      # {
      #   job_name = "thermometer";
      #   static_configs = [{ targets = [ "192.168.178.21:8000" ]; }];
      # }
      # {
      #   job_name = "esphome";
      #   static_configs = [{ targets = [ "192.168.178.77" ]; }];
      # }
    ];
    exporters.node.enable = true;
    # exporters.unifi = {
    #   enable = true;
    #   unifiAddress = "https://localhost:8443";
    #   unifiInsecure = true;
    #   unifiUsername = "ReadOnlyUser";
    #   unifiPassword = "ReadOnlyPassword";
    # };
  };
  services.yorick.paperless = {
    enable = true;
    openFirewall = true;
    scanner_ip = "192.168.2.49";
  };
  boot.zfs.requestEncryptionCredentials = false;
  networking.firewall = {
    interfaces.wg-y.allowedTCPPorts = [ 3000 9090 8443 ];
    # mqtt, wsdd, ??, minecraft
    allowedTCPPorts = [ 1883 5357 443 25565 ];
    # mqtt, wsdd, minecraft
    allowedUDPPorts = [ 1883 3702 25565 ];
  };
  services.rabbitmq = {
    enable = true;
    plugins = [ "rabbitmq_mqtt" "rabbitmq_management" ];
  };
  services.grafana = {
    enable = true;
    settings = {
      server.http_addr = "0.0.0.0";
      server.domain = "grafana.yori.cc";
      server.rootUrl = "https://grafana.yori.cc/";
      "auth.basic".enabled = false;
      "auth.google" = {
        enabled = true;
        allow_sign_up = false;
      };
      auth.disable_login_form = true;
    };
  };
  services.zigbee2mqtt = {
    enable = true;
    settings.availability = true;
    settings.device_options = {
      retain = true;
      legacy = false;
    };
    settings.serial.port = "/dev/ttyUSB0";
  };
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "default_config"
      "androidtv"
      "esphome"
      "met"
      "unifi" "yeelight" "plex" "frontend"
      "tado"
      "automation" "device_automation"
      "homewizard"
      "github" "backup"
      "mqtt"
      "brother"
      "spotify"
      "yamaha_musiccast"
      "ipp"
      "homekit_controller"
      #"unifiprotect"
    ];
    config = {
      media_player = [
        {
          platform = "androidtv";
          host = "192.168.2.181";
          name = "shield";
          device_class = "androidtv";
        }
      ];
      mobile_app = {};
      default_config = {};
      system_log = {};
      "map" = {};
      
      frontend.themes = "!include_dir_merge_named themes";
      automation = "!include automations.yaml";
      homeassistant = {
        name = "Home";
        latitude = "51.84";
        longitude = "5.85";
        elevation = "0";
        unit_system = "metric";
        time_zone = "Europe/Amsterdam";
        country = "NL";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "::1" ];
      };
    };
  };
  age.secrets = {
    grafana.file = ../../../secrets/grafana.env.age;
    frumar-mail-pass.file = ../../../secrets/frumar-mail-pass.age;
    acme-transip-key = {
      file = ../../../secrets/transip-key.age;
      mode = "770";
      group = "acme";
    };
  };
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.age.secrets.grafana.path;
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "*-*-01 02:00:00"; # monthly + 2 hours
    };
  };
  services.samba = {
    enable = false;
    openFirewall = false;
    shares.public = {
      path = "/data/plexmedia";
      browseable = "yes";
      "guest ok" = "yes";
      "hosts allow" = "192.168.178.0/255.255.255.0";
      "writeable" = "yes";
      "force user" = "nobody";
      "force directory mode" = "2777";
    };
  };
  services.samba-wsdd = {
    enable = true;
    interface = "eno1";
    hostname = "NAS";
  };
  services.sonarr = {
    enable = true;
    group = "plex";
    user = "plex";
    openFirewall = true;
  };
  services.radarr = {
    enable = true;
    group = "plex";
    user = "plex";
    openFirewall = true;
  };
  services.znapzend = {
    enable = true;
    pure = true;
    features = {
      zfsGetType = true;
      sendRaw = true;
    };
    zetup = {
      "frumar-new" = {
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
  users.users.plex.packages = with pkgs; [
    ffmpeg
  ];
  users.users.yorick.packages = with pkgs; [
    borgbackup
    bup
    fzf
    git-annex
    magic-wormhole
    python3
    ranger
    pyrosimple
    rtorrent
    jq
    mcrcon
    jdk17_headless
    unzip
    yscripts.absorb
  ];
  security.acme.certs."wildcard.yori.cc" = {
    domain = "*.yori.cc";
    dnsProvider = "transip";
    reloadServices = [ "nginx.service" ];
  };
  users.users.nginx.extraGroups = [ "acme" ];
  systemd.services."acme-wildcard.yori.cc".environment = {
    TRANSIP_ACCOUNT_NAME = "yorickvp";
    TRANSIP_PRIVATE_KEY_PATH = config.age.secrets.acme-transip-key.path;
  };
  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      tls = true;
      from = "frumar@yori.cc";
      host = "pennyworth.yori.cc";
      user = "frumar@yori.cc";
      passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.frumar-mail-pass.path}";
    };
  };
  services.smartd = {
    enable = true;
    notifications.mail = {
      enable = true;
      sender = "frumar@yori.cc";
      recipient = "yorickvanpelt@gmail.com";
    };
  };
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "yorickvanpelt@gmail.com" ];
    ZED_EMAIL_PROG = "/run/wrappers/bin/sendmail";
    ZED_EMAIL_OPTS = "@ADDRESS@";
    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;
    ZED_SCRUB_AFTER_RESILVER = true;
  };
}
