{ config, pkgs, lib, ... }: {
  imports = [
    ./fractal.nix
    ../../roles/server.nix
    ../../roles/homeserver.nix
    ./paperless.nix
    ./media.nix
    ./home-automation.nix
    ./cache.nix
    ../../services/backup.nix
  ];

  services.borgbackup.jobs.backup.paths = [ "/var/lib/hass" "/var/lib/paperless" "/var/lib/redis-paperless" "/var/lib/zigbee2mqtt" ];
  system.stateVersion = "15.09";
  networking.hostId = "0702dbe9";
  nixpkgs.overlays = [ (self: super: {
    openjdk8-bootstrap = super.openjdk8-bootstrap.override {
      gtkSupport = false;
    };
  }) ];

  security.y-selfsigned.enable = true;

  services.nginx = let
    sslForward = proxyPass: extra: lib.mkMerge [ {
      onlySSL = true;
      useACMEHost = "wildcard.yori.cc";
      locations."/" = {
        inherit proxyPass;
        proxyWebsockets = true;
      };
    } extra ];
  in {
    enable = true;
    virtualHosts = {
      "unifi.yori.cc" = sslForward "https://[::1]:8443" {
        locations."/".extraConfig = ''
          proxy_ssl_verify off;
          proxy_ssl_session_reuse on;
        '';
      };
      "grafana.yori.cc" = sslForward "http://127.0.0.1:3000" {};
      "prometheus.yori.cc" = sslForward "http://127.0.0.1:8428" {
        # only over VPN
        listen = [ { addr = "10.209.0.3"; port = 443; ssl = true; } ];
      };
      "plex.yori.cc" = sslForward "http://127.0.0.1:32400" {
        extraConfig = ''
          gzip on;
          gzip_vary on;
          gzip_min_length 1000;
	        gzip_proxied any;
	        gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
          proxy_http_version 1.1;
          proxy_buffering off;
        '';
      };
      "fooocus.yori.cc" = sslForward "http://192.168.2.135:7860" {}; 
      "priv.yori.cc" = let
        oauth2Block = ''
          # pass information via X-User and X-Email headers to backend,
          # requires running with --set-xauthrequest flag
          proxy_set_header X-User  $user;
          proxy_set_header X-Email $email;
  
          # if you enabled --cookie-refresh, this is needed for it to work with auth_request
          add_header Set-Cookie $auth_cookie;
        '';
        proxyOauth2 = proxyPass: {
          inherit proxyPass;
          extraConfig = oauth2Block;
        };
      in {
        onlySSL = true;
        useACMEHost = "wildcard.yori.cc";
        locations."/".root = pkgs.writeTextDir "index.html" ''
          <!DOCTYPE HTML>
          <ul>
          <li><a href="/paperless/">paperless</a>
          <li><a href="/sonarr/">sonarr</a>
          <li><a href="/radarr/">radarr</a>
          <li><a href="/transmission/">transmission</a>
          <li><a href="/victorialogs/select/vmui">victorialogs</a>
          <li><a href="/oauth2/sign_out?rd=/">sign out</a>
          </ul>
        '';
        locations."/sonarr" = proxyOauth2 "http://127.0.0.1:8989";
        locations."/radarr" = proxyOauth2 "http://127.0.0.1:7878";
        locations."/marvin-tracker/" = {
          proxyPass = "http://[::1]:${toString config.services.yorick.marvin-tracker.port}/";
          extraConfig = "auth_request off;";
          # handles auth using arg
        };
        locations."/paperless/" = proxyOauth2 "http://127.0.0.1:${toString config.services.paperless.port}/";
        locations."/media/" = {
          root = "/var/mediashare";
          extraConfig = "auth_request off;";
        };
        locations."/transmission/" = proxyOauth2 "http://unix:/torrent/sockets/transmission.sock";
        locations."/transmission/rpc" = lib.mkMerge [
          (proxyOauth2 "http://unix:/torrent/sockets/transmission.sock")
          { extraConfig = "auth_request off;"; }
        ];
        locations."/victorialogs/" = proxyOauth2 "http://127.0.0.1:9428/";
      };
      "frumar.yori.cc" = {
        enableACME = lib.mkForce false;
        inherit (config.security.y-selfsigned) sslCertificate sslCertificateKey;
      };
    };
  };
  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = [ "/data/plexmedia/ca" "/var/mediashare" "/torrent/sockets" ];
  boot.supportedFilesystems = [ "zfs" ];
  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi;
    mongodbPackage = pkgs.mongodb-7_0;
  };
  services.victoriametrics = {
    enable = true;
    retentionPeriod = "1y";
    prometheusConfig.scrape_configs = [
      {
        job_name = "node";
        static_configs = [{ targets = [
          "localhost:9100"
          "pennyworth.vpn.yori.cc:9100"
          "blackadder.vpn.yori.cc:9100"
        ]; }];
      }
      {
        job_name = "victoriametrics";
        static_configs = [{ targets = [ "http://localhost:8428/metrics" ]; }];
      }
      {
        job_name = "victorialogs";
        static_configs = [{ targets = [ "http://localhost:9428/metrics" ]; }];
      }
    ];
  };
  services.yorick.paperless = {
    enable = true;
    openFirewall = true;
    scanner_ip = "192.168.2.49";
  };
  boot.zfs.requestEncryptionCredentials = [ "frumar-new/userdata" ];
  networking.firewall = {
    # grafana, victoriametrics, victorialogs
    interfaces.wg-y.allowedTCPPorts = [ 3000 8428 9428 ];
    # mqtt, nats
    allowedTCPPorts = [ 1883 4222 ];
    # mqtt
    allowedUDPPorts = [ 1883 ];
  };
  services.grafana = {
    enable = true;
    settings = {
      server.http_addr = "0.0.0.0";
      server.domain = "grafana.yori.cc";
      server.root_url = "https://grafana.yori.cc/";
      "auth.basic".enabled = false;
      "auth.google" = {
        enabled = true;
        allow_sign_up = false;
      };
      auth.disable_login_form = true;
    };
  };
  age.secrets = {
    msmtp-mail-pass.file = ../../../secrets/frumar-mail-pass.age;
    grafana.file = ../../../secrets/grafana.env.age;
    oauth2-proxy.file = ../../../secrets/oauth2-proxy.age;
    zigbee2mqtt.file = ../../../secrets/zigbee2mqtt.env.age;
    marvin-tracker.file = ../../../secrets/marvin-tracker.env.age;
    frumar-disk-encryption.file = ../../../secrets/frumar-disk-encryption.age;
  };
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.age.secrets.grafana.path;
  systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = config.age.secrets.zigbee2mqtt.path;
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-01 02:00:00"; # monthly + 2 hours
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
  programs.msmtp.enable = true;
  services.smartd = {
    enable = true;
    notifications.mail.enable = true;
  };
  services.zfs.zed = {
    enableMail = true;
    settings = {
      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };
  services.oauth2-proxy = {
    enable = true;
    email.addresses = "yorickvanpelt@gmail.com";
    redirectURL = "https://priv.yori.cc/oauth2/callback";
    reverseProxy = true;
    keyFile = config.age.secrets.oauth2-proxy.path;
    setXauthrequest = true;
    nginx.virtualHosts."priv.yori.cc" = {
      allowed_emails = ["yorickvanpelt@gmail.com"];
    };
    nginx.domain = "priv.yori.cc";
    extraConfig.whitelist-domain = ["priv.yori.cc"];
  };
  services.nats = {
    enable = true;
    jetstream = true;
    settings = {
      mqtt.port = 1883;
      system_account = "SYS";
      accounts = {
        SYS.users = [ {
          user = "admin";
          password = "$2y$10$TWoKGC7/VKQRnIK163akm.0JRdhSA00lMMVn8fa1tPyKBgbED0BL2";
        } ];
        default = {
          jetstream = "enabled";
          users = [
            {
              user = "yorick";
              password = "$2y$10$EtQh8YX0I91X774PhDxhKOSGSc0IAAvGwZErVKV3z.IfeHTcT1.yy";
            }
            {
              user = "iot";
              password = "$2y$10$.JF/0CQ1PYCFPITsSXGj..k5v60rZvDc.LWCIDhZpoc93NyyIa5wS";
              allowed_connection_types = [ "MQTT" ];
            }
            {
              user = "zigbee2mqtt";
              password = "$2a$11$CC5NVYiTUeoa4A4w94NFMORO/0jhMR60JWgPUgjct8c2vg29wwIGG";
              allowed_connection_types = [ "MQTT" ];
            }
            {
              user = "marvin-tracker";
              password = "$2a$11$V9G2gT52obCsDOBwibHfMudnibwP/s3NwUjwvtsnlHfkn5kJHOOEe";
              allowed_connection_types = [ "MQTT" ];
            }
            {
              user = "govee2mqtt";
              password = "$2y$10$7EOQkxOjWdHV.hCb.a92JOAU30Qgok0faew/1xU3SJhaXVuKbZ1bm";
              allowed_connection_types = [ "MQTT" ];
            }
          ];
        };
      };
    };
  };
  services.yorick.marvin-tracker = {
    enable = true;
    secretFile = config.age.secrets.marvin-tracker.path;
  };
  services.yorick.cert."wildcard.yori.cc".enable = true;
  programs.fish.enable = true;
  services.victorialogs = {
    enable = true;
    extraOptions = [
      "-journald.streamFields=_HOSTNAME,_SYSTEMD_SLICE,_SYSTEMD_UNIT,SYSLOG_IDENTIFIER"
      "-memory.allowedPercent=10"
      "-retentionPeriod=14d"
      "-retention.maxDiskSpaceUsageBytes=10GiB"
    ];
  };
}
