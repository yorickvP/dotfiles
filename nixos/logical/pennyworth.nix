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
  vpn = import ../vpn.nix;
in {
  imports = [
    ../physical/hetznercloud.nix
    ../roles/server.nix
    ../modules/muflax-blog.nix
    ../services/backup.nix
    ../services/email.nix
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
  };

  services.muflax-blog = {
    enable = true;
    web-server = { port = 9001; };
    hidden-service = {
      hostname = "muflax65ngodyewp.onion";
      private_key = "/root/keys/http.muflax.key";
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
    "ubiquiti.yori.cc" = sslforward "https://${vpn.ips.woodhouse}:8443";
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
    "media.yori.cc" = sslforward "http://${vpn.ips.frumar}:32001";
  };
  deployment.keyys = [ <yori-nix/keys/http.muflax.key> ];
  networking.firewall.allowedUDPPorts = [ 31790 ]; # wg
  networking.wireguard.interfaces.wg-y.peers = lib.mkForce (lib.mapAttrsToList
    (machine: publicKey: {
      inherit publicKey;
      allowedIPs = [ "${vpn.ips.${machine}}/32" ];
    }) vpn.keys);
  services.prometheus.exporters.wireguard = { enable = true; };
  networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 9586 ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  environment.noXlibs = true;
  users.users.yorick.packages = with pkgs; [
    python2
    sshfs-fuse
    weechat
    ripgrep
  ];

}
