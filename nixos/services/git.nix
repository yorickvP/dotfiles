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
      extraGroups = [ "git" ];
      useDefaultShell = true;
      isSystemUser = true;
    };
    services.gitea = {
      enable = true;
      user = "git";
      database.user = "root";
      database.name = "gogs";
      database.createDatabase = false;
      #dump.enable = true; TODO: backups
      domain = cfg.vhost;
      rootUrl = "https://${cfg.vhost}/";
      httpAddress = "localhost";
      cookieSecure = true;
      log.level = "Warn";
      disableRegistration = true;
      settings.service = {
        REGISTER_EMAIL_CONFIRM = false;
        ENABLE_NOTIFY_MAIL = false;
        REQUIRE_SIGNIN_VIEW = false;
      };
      settings.picture.DISABLE_GRAVATAR = false;
      settings.mailer = {
        ENABLED = false;
        AVATAR_UPLOAD_PATH = "${config.services.gitea.stateDir}/data/avatars";
      };
    };
    services.nginx.virtualHosts.${vhost} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass =
          "http://127.0.0.1:${toString config.services.gitea.httpPort}";
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
  };
}