{ config, lib, pkgs, ... }:

let
  cfg = config.services.yorick.calibre-web;
in {
  disabledModules = [ "services/web-apps/calibre-web.nix" ];
  imports = [ ../modules/calibre-web.nix ];
  options.services.yorick.calibre-web = with lib; {
    enable = mkEnableOption "calibre-web";
    vhost = mkOption { type = types.str; };
  };
  config = lib.mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      options = {
        enableBookUploading = true;
        #enableBookConversion = true;
        extraConfig.config_kepubifypath = "${pkgs.kepubify}/bin/kepubify";
      };
    };
    services.nginx.virtualHosts.${cfg.vhost} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://[::1]:8083";
        proxyWebsockets = true;
      };
      locations."/kobo/" = {
        proxyPass = "http://[::1]:8083/kobo/";
        extraConfig = ''
          proxy_buffer_size 128k;
          proxy_buffers 4 256k;
          proxy_busy_buffers_size 256k;
        '';
      };
    };
  };
}
