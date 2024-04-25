{ lib, ... }: {
  services.nginx.virtualHosts."dk-stage.yori.cc" = {
    forceSSL = true;
    enableACME = true;
    globalRedirect = "staging.datakami.nl";
  };
}
