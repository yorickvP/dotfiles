{ config, lib, pkgs, ... }:

let
  cfg = config.services.yorick.website;
in with lib; {
  options.services.yorick = {
    website = {
      enable = mkEnableOption "yoricc website";
      vhost = mkOption { type = types.str; };
      pkg = mkOption {
        type = types.package;
        default = pkgs.yori-cc;
      };
    };
    redirect = mkOption {
      type = types.loaOf types.str;
      default = [ ];
    };
  };
  config.services.nginx.virtualHosts = with cfg;
    mkIf enable {
      ${vhost} = {
        enableACME = true;
        forceSSL = true;
        locations."/".root = "${pkg}/web";
      };
    };

}
