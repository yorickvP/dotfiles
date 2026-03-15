{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.services.muflax-blog;
  blog = inputs.muflax-blog.packages.${pkgs.stdenv.system}.default.overrideAttrs (old: {
    buildPhase =
      old.buildPhase
      + "\n"
      + ''
        grep -lr '[^@]muflax.com' out | xargs -r sed -i 's/\([^@]\)muflax.com/\1${cfg.hidden-service.hostname}/g'
      '';
  });
in
with lib;
{
  options.services.muflax-blog = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    web-server = {
      port = mkOption { type = types.int; };
    };
    hidden-service = {
      hostname = mkOption { type = types.str; };
      secretKeyFile = mkOption { type = types.path; };
    };
  };
  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      serverNamesHashBucketSize = 128;
      appendHttpConfig = ''
        server {
          index index.html;
          port_in_redirect off;
          listen 127.0.0.1:${toString cfg.web-server.port};
          server_name ${cfg.hidden-service.hostname};
          root ${blog}/muflax;
        }
      ''
      + concatStringsSep "\n" (
        map
          (site: ''
            server {
              index index.html;
              port_in_redirect off;
              listen 127.0.0.1:${toString cfg.web-server.port};
              server_name ${site}.${cfg.hidden-service.hostname};
              root ${blog}/${site};
            }
          '')
          [
            "daily"
            "gospel"
            "blog"
          ]
      );
    };
    services.tor.enable = true;
    services.tor.relay.onionServices.muflax = {
      map = [
        {
          port = 80;
          target.port = cfg.web-server.port;
        }
      ];
      secretKey = cfg.hidden-service.secretKeyFile;
    };
  };
}
