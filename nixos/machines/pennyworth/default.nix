# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  sslforward = proxyPass: {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      inherit proxyPass;
      proxyWebsockets = true;
    };
  };
  vpn = import ../../vpn.nix;
in {
  imports = [
    ./hetznercloud.nix
    ../../roles/server.nix
    ../../roles/datakami.nix
    ../../services/backup.nix
    ../../services/email.nix
    ../../services/calibre-web.nix
  ];

  system.stateVersion = "19.03";

  services.nginx.enable = true;
  services.yorick = {
    public = {
      enable = true;
      vhost = "pub.yori.cc";
    };
    website = {
      enable = true;
      vhost = "yorickvanpelt.nl";
    };
    git = {
      enable = true;
      vhost = "git.yori.cc";
    };
    muflax-church = {
      enable = true;
      vhost = "muflax.church";
    };
    calibre-web = {
      enable = true;
      vhost = "calibre.yori.cc";
    };
  };

  age.secrets.muflax.file = ../../../secrets/http.muflax.age;
  services.muflax-blog = {
    enable = true;
    web-server = { port = 9001; };
    hidden-service = {
      hostname = "muflax65ngodyewp.onion";
      private_key = config.age.secrets.muflax.path;
    };
  };
  services.nginx.commonHttpConfig = ''
    access_log off; 
  '';
  services.nginx.virtualHosts = {
    "yori.cc" = {
      enableACME = true;
      forceSSL = true;
      globalRedirect = "yorickvanpelt.nl";
    };
    "yorickvanpelt.nl".locations."/p1".return =
      "301 https://git.yori.cc/yorick/meterkast";
    "grafana.yori.cc" = sslforward "http://${vpn.ips.frumar}:3000";
    #"ubiquiti.yori.cc" = sslforward "https://${vpn.ips.frumar}:8443";
    "prometheus.yori.cc" = {
      # only over vpn
      listen = [{
        addr = "10.209.0.1";
        port = 80;
      }];
      locations."/".proxyPass = "http://10.209.0.3:9090";
    };
    "pub.yori.cc".locations."/muflax/".extraConfig = ''
      rewrite ^/muflax/(.*)$ https://alt.muflax.church/$1 permanent;
    '';
    "plex.yori.cc" = (sslforward "http://${vpn.ips.frumar}:32400") // {
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
  };
  networking.firewall.allowedUDPPorts = [ 31790 ]; # wg
  networking.firewall.allowedTCPPorts = [ 60307 ]; # weechat relay
  security.acme.certs."pennyworth.yori.cc".postRun = ''
    cat fullchain.pem key.pem > /home/yorick/.weechat/ssl/relay.pem
    chown yorick:users /home/yorick/.weechat/ssl/relay.pem
    chmod 0600 $_
  '';
  networking.wireguard.interfaces.wg-y.peers = lib.mkForce (lib.mapAttrsToList
    (machine: publicKey: {
      inherit publicKey;
      allowedIPs = [ "${vpn.ips.${machine}}/32" ];
    }) vpn.keys);
  services.prometheus.exporters.wireguard = { enable = true; };
  networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 9586 ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  users.users.yorick.packages = with pkgs; [
    sshfs-fuse
    weechat
    ripgrep
  ];
  nix.settings.allowed-users = [ "@wheel" ];

}
