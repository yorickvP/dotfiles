{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  cfg = config.services.yorick.website;
in
with lib;
{
  options.services.yorick = {
    website = {
      enable = mkEnableOption "yoricc website";
      vhost = mkOption { type = types.str; };
      pkg = mkOption {
        type = types.package;
        default = pkgs.yori-cc;
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
    redirect = mkOption {
      type = types.loaOf types.str;
      default = [ ];
    };
  };
  config.services.nginx.virtualHosts =
    with cfg;
    mkIf enable {
      ${vhost} = lib.mkMerge [
        cfg.nginx
        {
          locations."/".root = "${pkg}/web";
        }
      ];
    };

}
