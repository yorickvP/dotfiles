{
  config,
  lib,
  ...
}:

let
  cfg = config.services.yorick.cert."wildcard.yori.cc";
in
{
  options.services.yorick.cert."wildcard.yori.cc" = with lib; {
    enable = mkEnableOption "wildcard.yori.cc cert";
  };
  config = lib.mkIf cfg.enable {
    age.secrets.acme.file = ../../secrets/acme.age;
    security.acme.certs."wildcard.yori.cc" = {
      domain = "*.yori.cc";
      dnsProvider = "cloudflare";
      reloadServices = [ "nginx.service" ];
      environmentFile = config.age.secrets.acme.path;
    };
    users.users.nginx.extraGroups = [ "acme" ];
  };
}
