{ config, pkgs, lib, ... }: {
  imports = [
    ./fractal.nix
    ../../roles/server.nix
    ../../roles/homeserver.nix
    ./paperless.nix
    ./media.nix
    ./home-automation.nix
  ];

  system.stateVersion = "15.09";
  networking.hostId = "0702dbe9";
  nixpkgs.overlays = [ (self: super: {
    openjdk8-bootstrap = super.openjdk8-bootstrap.override {
      gtkSupport = false;
    };
  }) ];

  security.y-selfsigned.enable = true;

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
    virtualHosts."priv.yori.cc" = let
      oauth2Block = ''
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;

        # pass information via X-User and X-Email headers to backend,
        # requires running with --set-xauthrequest flag
        auth_request_set $user   $upstream_http_x_auth_request_user;
        auth_request_set $email  $upstream_http_x_auth_request_email;
        proxy_set_header X-User  $user;
        proxy_set_header X-Email $email;

        # if you enabled --cookie-refresh, this is needed for it to work with auth_request
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        add_header Set-Cookie $auth_cookie;
      '';
    in {
      onlySSL = true;
      useACMEHost = "wildcard.yori.cc";
      locations."/".proxyPass = "http://127.0.0.1:4000";
      locations."/sonarr" = {
        proxyPass = "http://127.0.0.1:8989";
        extraConfig = oauth2Block;
      };
      locations."/radarr" = {
        proxyPass = "http://127.0.0.1:7878";
        extraConfig = oauth2Block;
      };
      locations."/marvin-tracker/" = {
        proxyPass = "http://[::1]:4001/";
        # handles auth using arg
      };
      locations."/paperless/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.paperless.port}/";
        extraConfig = oauth2Block;
      };
      locations."/media/" = {
        root = "/var/mediashare";
      };
    };
    virtualHosts."fooocus.yori.cc" = {
      onlySSL = true;
      useACMEHost = "wildcard.yori.cc";
      locations."/" = {
        proxyPass = "http://192.168.2.135:7860";
        proxyWebsockets = true;
      };
    };
    virtualHosts."frumar.yori.cc" = {
      enableACME = lib.mkForce false;
      inherit (config.security.y-selfsigned) sslCertificate sslCertificateKey;
    };
  };
  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = [ "/data/plexmedia/ca" "/var/mediashare" ];
  boot.supportedFilesystems = [ "zfs" ];
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
    scrapeConfigs = [{
      job_name = "node";
      static_configs = [{ targets = [ "localhost:9100" ]; }];
    }];
    exporters.node.enable = true;
  };
  services.yorick.paperless = {
    enable = true;
    openFirewall = true;
    scanner_ip = "192.168.2.49";
  };
  boot.zfs.requestEncryptionCredentials = false;
  networking.firewall = {
    interfaces.wg-y.allowedTCPPorts = [ 3000 9090 ]; # grafana and prometheus via pennyworth
    # mqtt
    allowedTCPPorts = [ 1883 ];
    # mqtt
    allowedUDPPorts = [ 1883 ];
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
    acme-transip-key = {
      file = ../../../secrets/transip-key.age;
      mode = "770";
      group = "acme";
    };
    frumar-mail-pass.file = ../../../secrets/frumar-mail-pass.age;
    grafana.file = ../../../secrets/grafana.env.age;
    oauth2-proxy.file = ../../../secrets/oauth2-proxy.age;
  };
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.age.secrets.grafana.path;
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-01 02:00:00"; # monthly + 2 hours
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
  services.oauth2_proxy = {
    enable = true;
    email.addresses = "yorickvanpelt@gmail.com";
    redirectURL = "https://priv.yori.cc/oauth2/callback";
    reverseProxy = true;
    keyFile = config.age.secrets.oauth2-proxy.path;
    setXauthrequest = true;
    nginx.virtualHosts = [ "priv.yori.cc" ];
    extraConfig.whitelist-domain = ["priv.yori.cc"];
  };
  services.yorick.marvin-tracker.enable = true;
}
