{ config, lib, pkgs, ... }:

let
  cfg = config.services.yorick.git;
  inherit (cfg) vhost;
in {
  options.services.yorick.git = with lib; {
    enable = mkEnableOption "git";
    vhost = mkOption { type = types.str; };
  };
  config = lib.mkIf cfg.enable {
    users.extraUsers.git = {
      createHome = true;
      home = config.services.gitea.stateDir;
      group = "git";
      useDefaultShell = true;
      isSystemUser = true;
    };
    users.groups.git = {};
    services.gitea = {
      enable = true;
      user = "git";
      database.user = "root";
      database.name = "gogs";
      database.createDatabase = false;
      #dump.enable = true; TODO: backups
      settings = {
        server = {
          ROOT_URL = "https://${cfg.vhost}/";
          HTTP_ADDR = "localhost";
          DOMAIN = cfg.vhost;
        };
        log.LEVEL = "Warn";
        service = {
          DISABLE_REGISTRATION = true;
          REGISTER_EMAIL_CONFIRM = false;
          COOKIE_SECURE = true;
          ENABLE_NOTIFY_MAIL = false;
          REQUIRE_SIGNIN_VIEW = false;
        };
        picture.DISABLE_GRAVATAR = false;
        mailer = {
          ENABLED = false;
          AVATAR_UPLOAD_PATH = "${config.services.gitea.stateDir}/data/avatars";
        };
      };
    };
    services.nginx.virtualHosts.${vhost} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass =
          "http://127.0.0.1:${toString config.services.gitea.settings.server.HTTP_PORT}";
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
  };
}
