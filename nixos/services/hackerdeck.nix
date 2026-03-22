{
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.services.yorick.hackerdeck;
in
{
  options.services.yorick.hackerdeck = with lib; {
    enable = mkEnableOption "hackerdeck";
    vhost = mkOption {
      type = types.str;
      description = "Nginx virtual host name";
    };
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
  };
  config = lib.mkIf cfg.enable {
    services.hackerdeck = {
      enable = true;
      uds = "/run/hackerdeck/hackerdeck.sock";
      environmentFile = config.age.secrets.hackerdeck-env.path;
    };
    services.postgresql = {
      enable = true;
      extensions = ps: [ ps.pgvector ];
      ensureDatabases = [ "hackerdeck" ];
      ensureUsers = [
        {
          name = "hackerdeck";
          ensureDBOwnership = true;
        }
      ];
    };
    services.nginx.virtualHosts.${cfg.vhost} = lib.mkMerge [
      cfg.nginx
      {
        locations."/".proxyPass = "http://unix:${config.services.hackerdeck.uds}";
      }
    ];
  };
}
