{ config, pkgs, lib, ... }:
{
  imports = [ 
    ../physical/fractal.nix
    ../roles/server.nix
    ../roles/homeserver.nix
    ../services/torrent-wg.nix
  ];

  deployment.keyys = [ ../keys/grafana.env ];

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
    enable = true; name = "mullvad-nl4"; namespace = "torrent";
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
    extraFlags = [
      "--web.enable-admin-api"
    ];
    # victoriametrics
    remoteWrite = [ { url = "http://127.0.0.1:8428/api/v1/write"; } ];
    scrapeConfigs = [ {
      job_name = "smartmeter";
      # prometheus doesn't support mdns :thinking_face:
      static_configs = [ { targets = [ "192.168.178.30" ]; } ];
      scrape_interval = "10s";
    } {
      job_name = "node";
      static_configs = [ { targets = [ "localhost:9100" ]; } ];
    # } {
    #   job_name = "unifi";
    #   static_configs = [ { targets = [ "localhost:9130" ]; } ];
    } {
      job_name = "thermometer";
      static_configs = [ { targets = [ "192.168.178.21:8000" ]; } ];  
    }];
    exporters.node.enable = true;
    # exporters.unifi = {
    #   enable = true;
    #   unifiAddress = "https://woodhouse.home.yori.cc:8443";
    #   unifiInsecure = true;
    #   unifiUsername = "ReadOnlyUser";
    #   unifiPassword = "ReadOnlyPassword";
    # };
  };
  boot.zfs.requestEncryptionCredentials = false;
  networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 3000 9090 ];
  networking.firewall.allowedTCPPorts = [ 1883 ];
  networking.firewall.allowedUDPPorts = [ 1883 ];
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
  systemd.services.grafana.serviceConfig.EnvironmentFile = "/root/keys/grafana.env";
  services.zfs = {
    trim.enable = false; # no ssd's
    autoScrub = {
      enable = true;
      interval = "*-*-01 02:00:00"; # monthly + 2 hours
    };
  };
}
