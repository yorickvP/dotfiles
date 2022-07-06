{ config, pkgs, lib, ... }: {
  imports = [
    ../physical/fractal.nix
    ../roles/server.nix
    ../roles/homeserver.nix
    ../services/torrent-wg.nix
  ];

  system.stateVersion = "15.09";
  networking.hostId = "0702dbe9";

  services.nginx.enable = false;
  # services.nginx.virtualHosts."${config.networking.hostName}" = {
  #   enableACME = lib.mkForce false;
  #   forceSSL = lib.mkForce false;
  #   default = true;
  # };
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
      {
        job_name = "smartmeter";
        # prometheus doesn't support mdns :thinking_face:
        static_configs = [{ targets = [ "192.168.178.30" ]; }];
        scrape_interval = "10s";
      }
      {
        job_name = "node";
        static_configs = [{ targets = [ "localhost:9100" ]; }];
        # } {
        #   job_name = "unifi";
        #   static_configs = [ { targets = [ "localhost:9130" ]; } ];
      }
      {
        job_name = "thermometer";
        static_configs = [{ targets = [ "192.168.178.21:8000" ]; }];
      }
      {
        job_name = "esphome";
        static_configs = [{ targets = [ "192.168.178.77" ]; }];
      }
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
  boot.zfs.requestEncryptionCredentials = false;
  networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 3000 9090 ];
  networking.firewall.allowedTCPPorts = [ 1883 5357 ];
  networking.firewall.allowedUDPPorts = [ 1883 3702 ];
  services.rabbitmq = {
    enable = true;
    plugins = [ "rabbitmq_mqtt" "rabbitmq_management" ];
  };
  services.grafana = {
    enable = true;
    addr = "0.0.0.0";
    domain = "grafana.yori.cc";
    rootUrl = "https://grafana.yori.cc/";
    extraOptions = {
      AUTH_BASIC_ENABLED = "false";
      AUTH_DISABLE_LOGIN_FORM = "true";
      AUTH_GOOGLE_ENABLED = "true";
      AUTH_GOOGLE_ALLOW_SIGN_UP = "false";
    };
  };
  age.secrets.grafana.file = ../../secrets/grafana.env.age;
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.age.secrets.grafana.path;
  services.zfs = {
    trim.enable = false; # no ssd's
    autoScrub = {
      enable = true;
      interval = "*-*-01 02:00:00"; # monthly + 2 hours
    };
  };
  services.samba = {
    enable = true;
    openFirewall = true;
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
    interface = "eno2";
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
      "frumar-new/plexmedia" = {
        plan = "1w=>6h,1m=>1w,1y=>1m,2y=>6m,50y=>1y";
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
    pyroscope
    rtorrent
  ];
}
