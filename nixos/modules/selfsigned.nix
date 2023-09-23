{ pkgs, config, lib, ...}: let
  cfg = config.security.y-selfsigned;
in {
  options.security.y-selfsigned = with lib; {
    enable = mkEnableOption "Enable generating a self-signed certificate";
    directory = mkOption {
      type = types.str;
      default = "/var/lib/selfsign";
      description = "Directory to store the self-signed certificate";
    };
    domain = mkOption {
      type = types.str;
      default = "selfsigned.local";
      description = "Domain to generate the self-signed certificate for";
    };
    sslCertificate = mkOption {
      type = types.str;
      readOnly = true;
      default = "${cfg.directory}/${cfg.domain}/cert.pem";
      description = "Path to the self-signed certificate";
    };
    sslCertificateKey = mkOption {
      type = types.str;
      readOnly = true;
      default = "${cfg.directory}/${cfg.domain}/key.pem";
      description = "Path to the self-signed certificate key";
    };
    user = mkOption {
      type = types.str;
      default = "nginx";
      description = "User to run the self-signed certificate generator as";
    };
    group = mkOption {
      type = types.str;
      default = "nginx";
      description = "Group to run the self-signed certificate generator as";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = lib.mkAfter [
      "d ${cfg.directory} 0700 ${cfg.user} ${cfg.group}"
    ];
    systemd.services."y-selfsigned-ca" = {
      description = "Generate self-signed fallback";
      path = with pkgs; [ minica ];
      unitConfig = {
        ConditionPathExists = "!${cfg.sslCertificateKey}";
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        UMask = "0077";
        Type = "oneshot";
        PrivateTmp = true;
        WorkingDirectory = cfg.directory;
      };
      script = "minica --domains ${cfg.domain}";
    };
    systemd.services.nginx = {
      requires = [ "y-selfsigned-ca.service" ];
      after = [ "y-selfsigned-ca.service" ];
    };
  };
}
