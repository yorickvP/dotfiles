{
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.services.yorick.public;
in
{
  options.services.yorick.public = with lib; {
    enable = mkEnableOption "public hosting";
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
  };
  #imports = [../modules/nginx.nix];
  config = lib.mkIf cfg.enable {
    systemd.services.nginx.serviceConfig = {
      ProtectHome = "tmpfs";
      UMask = lib.mkForce "0022";
      BindReadOnlyPaths = [ "/home/public/public" ];
    };
    users.users.public = {
      home = "/home/public";
      group = "public";
      useDefaultShell = true;
      isSystemUser = true;
      openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [ public ];
      createHome = false; # sets wrong permissions
    };
    users.groups.public = { };
    services.nginx.virtualHosts.${cfg.vhost} = lib.mkMerge [
      cfg.nginx
      {
        locations."/" = {
          root = "/home/public/public";
          index = "index.html";
        };
        extraConfig = ''
          charset utf-8;
        '';
      }
    ];
  };
}
