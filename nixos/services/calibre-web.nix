{ config, lib, pkgs, modulesPath, ... }:

let
  cfg = config.services.yorick.calibre-web;
in {
  options.services.yorick.calibre-web = with lib; {
    enable = mkEnableOption "calibre-web";
    vhost = mkOption { type = types.str; };
    nginx = mkOption {
      type = types.submodule (recursiveUpdate (import
        (modulesPath + "/services/web-servers/nginx/vhost-options.nix") {
          inherit config lib;
        }) { });
      default = { };
      description = ''
        With this option, you can customize the nginx virtualHost settings.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      options = {
        enableBookUploading = true;
        #enableBookConversion = true;
        enableKepubify = true;
      };
    };
    services.nginx.virtualHosts.${cfg.vhost} = lib.mkMerge [
      cfg.nginx
      {
        locations."/" = {
          proxyPass = "http://[::1]:8083";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 64M;
          '';
        };
        locations."/kobo/" = {
          proxyPass = "http://[::1]:8083/kobo/";
          extraConfig = ''
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
          '';
        };
      }
    ];
  };
}
