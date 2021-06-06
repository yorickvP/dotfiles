{ config, pkgs, lib, ... }:
let cfg = config.services.yorick.public;
in {
  options.services.yorick.public = {
    enable = lib.mkEnableOption "public hosting";
    vhost = lib.mkOption { type = lib.types.str; };
  };
  #imports = [../modules/nginx.nix];
  config = lib.mkIf cfg.enable {
    systemd.services.nginx.serviceConfig = {
      ProtectHome = "tmpfs";
      UMask = lib.mkForce "0022";
      BindReadOnlyPaths = [ "/home/public/public" ];
    };
    users.extraUsers.public = {
      home = "/home/public";
      useDefaultShell = true;
      isSystemUser = true;
      openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [ public ];
      createHome = false; # sets wrong permissions
    };
    services.nginx.virtualHosts.${cfg.vhost} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        root = "/home/public/public";
        index = "index.html";
      };
    };
  };
}
