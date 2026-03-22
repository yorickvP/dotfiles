{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./fractal.nix
    ../../roles/server.nix
    ../../roles/homeserver.nix
    ./paperless.nix
    ./media.nix
    ./home-automation.nix
    ../../services/cache.nix
    ./gitea-actions-runner.nix
    ../../services/backup.nix
  ];

  services.borgbackup.jobs.backup = {
    preHook = ''
      /run/current-system/sw/bin/zfs destroy ssdpool/root/var@borgbackup || true
      /run/current-system/sw/bin/zfs snapshot ssdpool/root/var@borgbackup
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
  system.stateVersion = "15.09";
  networking.hostId = "0702dbe9";
  nixpkgs.overlays = [
    (self: super: {
      openjdk8-bootstrap = super.openjdk8-bootstrap.override {
        gtkSupport = false;
      };
    })
  ];

  security.y-selfsigned.enable = true;

  services.nginx =
    let
      sslForward =
        proxyPass: extra:
        lib.mkMerge [
          {
            onlySSL = true;
            useACMEHost = "wildcard.yori.cc";
            locations."/" = {
              inherit proxyPass;
              proxyWebsockets = true;
            };
          }
          extra
        ];
    in
    {
      enable = true;
      virtualHosts = {
        "unifi.yori.cc" = sslForward "https://[::1]:8443" {
          locations."/".extraConfig = ''
            proxy_ssl_verify off;
            proxy_ssl_session_reuse on;
          '';
        };
        "grafana.yori.cc" = sslForward "http://127.0.0.1:3000" { };
        "prometheus.yori.cc" = sslForward "http://127.0.0.1:8428" {
          # only over VPN
          listen = [
            {
              addr = "10.209.0.3";
              port = 443;
              ssl = true;
            }
          ];
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
        "immich.yori.cc" = sslForward "http://[::1]:2283" {
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_request_buffering off;
            client_body_buffer_size 1024k;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout 600s;
          '';
        };
        "priv.yori.cc" =
          let
            oauth2Block = ''
              # pass information via X-User and X-Email headers to backend,
              # requires running with --set-xauthrequest flag
              auth_request_set $user   $upstream_http_x_auth_request_user;
              auth_request_set $email  $upstream_http_x_auth_request_email;
              auth_request_set $auth_cookie $upstream_http_set_cookie;

              proxy_set_header X-User  $user;
              proxy_set_header X-Email $email;

              # if you enabled --cookie-refresh, this is needed for it to work with auth_request
              add_header Set-Cookie $auth_cookie;
            '';
            proxyOauth2 = proxyPass: {
              inherit proxyPass;
              extraConfig = oauth2Block;
            };
          in
          {
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
            locations."/paperless/" =
              proxyOauth2 "http://127.0.0.1:${toString config.services.paperless.port}/";
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
  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = [
    "/data/plexmedia/ca"
    "/var/mediashare"
    "/torrent/sockets"
  ];
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
  };
  services.yorick.paperless = {
    enable = true;
    openFirewall = true;
    scanner_ip = "192.168.2.49";
  };
  boot.zfs.requestEncryptionCredentials = [ "frumar-new/userdata" ];
  networking.firewall = {
    # grafana, victoriametrics, victorialogs
    interfaces.wg-y.allowedTCPPorts = [
      3000
      8428
      9428
    ];
    # mqtt, nats
    allowedTCPPorts = [
      1883
      4222
    ];
    # mqtt
    allowedUDPPorts = [ 1883 ];
  };
  services.grafana = {
    enable = true;
    settings = {
      server.http_addr = "0.0.0.0";
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
      allowed_emails = [ "yorickvanpelt@gmail.com" ];
    };
    nginx.domain = "priv.yori.cc";
    extraConfig.whitelist-domain = [ "priv.yori.cc" ];
    provider = "oidc";
    scope = "openai email profile groups";
    oidcIssuerUrl = "https://pocket-id.yori.cc";
    extraConfig.code-challenge-method = "S256";
  };
  systemd.services.oauth2-proxy = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
  services.nats = {
    enable = true;
    jetstream = true;
    settings = {
      mqtt.port = 1883;
      system_account = "SYS";
      accounts = {
        SYS.users = [
          {
            user = "admin";
            password = "$2y$10$TWoKGC7/VKQRnIK163akm.0JRdhSA00lMMVn8fa1tPyKBgbED0BL2";
          }
        ];
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
            {
              user = "ci";
              password = "$2y$10$BXT8HfMegVz33NMc7WeuOeXXOk6YGyG0IucnWl6gh5RCRTjL4a4xK";
              allowed_connection_types = [ "MQTT" ];
              permissions.publish.allow = [ "yorick.git.>" ];
              permissions.subscribe.deny = [ ">" ];
            }
            {
              user = "ci-puller";
              password = "$2y$10$PufvT5B./pOZo3IhsQmadeZSP/xmIXDY5oB7RHzX7I2i20dxGFQOW";
              allowed_connection_types = [ "MQTT" ];
              permissions.subscribe.allow = [ "yorick.git.>" "$MQTT.sub.>" ];
              permissions.publish.deny = [ ">" ];
            }
          ];
        };
      };
    };
  };
  age.secrets.attic.file = ../../../secrets/attic.env.age;
  services.yorick.cache = {
    enable = true;
    vhost = "cache.yori.cc";
    nginx = {
      onlySSL = true;
      useACMEHost = "wildcard.yori.cc";
    };
    secretFile = config.age.secrets.attic.path;
  };
  services.postgresql.package = pkgs.postgresql_15;
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
  services.immich.enable = true;
}
