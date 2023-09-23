{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.services.nginx.enable {
    services.nginx = {
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      serverTokens = false;
      sslDhparam = "/etc/nginx/dhparam.pem";
      virtualHosts."${config.networking.hostName}.yori.cc" = {
        enableACME = true;
        forceSSL = true;
        default = true;
      };
    };
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    system.activationScripts.nginxdhparams = ''
      if ! [[ -e /etc/nginx/dhparam.pem ]]; then
        mkdir -p /etc/nginx/
        ${pkgs.openssl}/bin/openssl dhparam -out /etc/nginx/dhparam.pem 2048
        chown nginx:nginx /etc/nginx/dhparam.pem
      fi
    '';
  };

}
