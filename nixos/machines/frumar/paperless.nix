{ config, lib, pkgs, ... }:
let cfg = config.services.yorick.paperless;
in {
  options.services.yorick.paperless = with lib; {
    enable = mkEnableOption "yorick paperless";
    openFirewall = mkEnableOption "open firewall for scanner";
    scanner_ip = mkOption {
      type = types.str;
    };
  };
  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.openFirewall {
      connectionTrackingModules = [ "ftp" ];
      extraCommands = ''
        iptables -t raw -A PREROUTING -i eno1 -s ${cfg.scanner_ip}/32 -p tcp --dport 21 -j CT --helper ftp
        iptables -A nixos-fw -p tcp -m tcp --dport 21 -s ${cfg.scanner_ip}/32 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -t raw -D PREROUTING -i eno1 -s ${cfg.scanner_ip}/32 -p tcp --dport 21 -j CT --helper ftp
        iptables -D nixos-fw -p tcp -m tcp --dport 21 -s ${cfg.scanner_ip}/32 -j nixos-fw-accept
      '';
    };

    users.users.ads1600w = {
      home = "/var/ads1600w";
      group = "ads1600w";
      initialHashedPassword =
        "$6$q7E6hnTHHt9v.$OHZjuWISanANGwfhznWwfDlHAqbXBjqcr/q0lGe9ff2r.X9xCSoLP4giME5J9WoEUNuWssMLGBPMfXowBjXg70";
      isSystemUser = true;
      shell = "${pkgs.shadow}/bin/nologin";
      createHome = true;
    };
    users.groups.ads1600w = { };

    services.vsftpd = {
      enable = true;
      localUsers = true;
      writeEnable = true;
      chrootlocalUser = true;
      allowWriteableChroot = true;
      extraConfig = "local_umask=007";
      userlist = [ "ads1600w" ];
    };
    # todo: back up this dir
    services.paperless.enable = true;
    services.paperless.settings = {
      # todo: PAPERLESS_ENABLE_HTTP_REMOTE_USER, PAPERLESS_LOGOUT_REDIRECT_URL
      PAPERLESS_URL = "https://priv.yori.cc";
      PAPERLESS_FORCE_SCRIPT_NAME = "/paperless";
      PAPERLESS_STATIC_URL = "/paperless/static/";
    };
    users.users.paperless.extraGroups = [ "ads1600w" ];
  };
}
