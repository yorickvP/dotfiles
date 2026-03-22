{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.services.yorick.cache;
in
{
  options.services.yorick.cache = with lib; {
    enable = mkEnableOption "attic binary cache";
    vhost = mkOption { type = types.str; };
    nginx = mkOption {
      type = types.submodule (
        recursiveUpdate (import (modulesPath + "/services/web-servers/nginx/vhost-options.nix") {
          inherit config lib;
        }) { }
      );
      default = { };
      description = ''
        With this option, you can customize the nginx virtualHost settings.
      '';
    };
    secretFile = mkOption {
      type = types.path;
      description = "Path to the attic environment file";
    };
  };
  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts.${cfg.vhost} = lib.mkMerge [
      cfg.nginx
      {
        locations."/" = {
          proxyPass = "http://[::]:8091";
          recommendedProxySettings = true;
        };
        extraConfig = ''
          client_max_body_size 8000M;
          proxy_request_buffering off;
          proxy_read_timeout 600s;
        '';
      }
    ];
    services.atticd = {
      enable = true;
      environmentFile = cfg.secretFile;
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
    systemd.services.atticd = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };
    systemd.tmpfiles.rules = with config.services.atticd; [
      "d /attic 0770 ${user} ${group}"
    ];
    users.users.${config.services.atticd.user} = {
      isSystemUser = true;
      createHome = false;
      group = config.services.atticd.group;
    };
    users.groups.${config.services.atticd.group} = { };
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "atticd" ];
      ensureUsers = [
        {
          name = "atticd";
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
