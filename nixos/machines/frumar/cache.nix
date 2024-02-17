{ config, pkgs, lib, inputs, ... }: {
  imports = [
    inputs.attic.nixosModules.atticd
  ];
  age.secrets.attic.file = ../../../secrets/attic.env.age;

  services.nginx.virtualHosts."cache.yori.cc" = {
    onlySSL = true;
    useACMEHost = "wildcard.yori.cc";
    locations."/" = {
      proxyPass = "http://[::]:8091";
      recommendedProxySettings = true;
    };
    extraConfig = ''
      client_max_body_size 8000M;
      proxy_request_buffering off;
      proxy_read_timeout 600s;
    '';
  };
  services.atticd = {
    enable = true;
    credentialsFile = config.age.secrets.attic.path;
    settings = {
      storage = {
        type = "local";
        path = "/attic";
      };
      database.url = "postgresql:///atticd";
      listen = "[::]:8091";
      chunking = {
        nar-size-threshold = 128 * 1024;
        min-size = 32 * 1024;
        avg-size = 128 * 1024;
        max-size = 512 * 1024;
      };
    };
  };
  systemd.tmpfiles.rules = with config.services.atticd; [
    "d /attic 0770 ${user} ${group}"
  ];
  users.users.${config.services.atticd.user} = {
    isSystemUser = true;
    createHome = false;
    group = config.services.atticd.group;
  };
  users.groups.${config.services.atticd.group} = {};
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    ensureDatabases = [ "atticd" ];
    ensureUsers = [ {
      name = "atticd";
      ensureDBOwnership = true;
    } ];
  };
}
