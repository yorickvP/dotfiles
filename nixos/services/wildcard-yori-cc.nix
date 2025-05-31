{
  config,
  lib,
  pkgs,
  modulesPath,
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
    age.secrets.acme-transip-key = {
      file = ../../secrets/transip-key.age;
      mode = "770";
      group = "acme";
    };
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
  };
}
