{
  config,
  lib,
  pkgs,
  ...
}:

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
      commonHttpConfig = ''
        proxy_set_header X-Middleware-Subrequest "";
      '';
    };
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    networking.firewall.allowedUDPPorts = [
      443 # QUIC
    ];
    system.activationScripts.nginxdhparams = ''
      bits=4096
      regen=0
      if ! [[ -e /etc/nginx/dhparam.pem ]]; then
        regen=1
      elif ! ${pkgs.openssl}/bin/openssl dhparam -in /etc/nginx/dhparam.pem -text 2>/dev/null | head -1 | grep -q "$bits bit"; then
        regen=1
      fi
      if [[ "$regen" -eq 1 ]]; then
        mkdir -p /etc/nginx/
        ${pkgs.openssl}/bin/openssl dhparam -out /etc/nginx/dhparam.pem "$bits"
        chown nginx:nginx /etc/nginx/dhparam.pem
      fi
    '';
  };

}
