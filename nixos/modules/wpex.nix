{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.wpex;
in
{
  options.services.wpex = {
    enable = lib.mkEnableOption "wpex WireGuard packet relay";

    port = lib.mkOption {
      type = lib.types.port;
      default = 40000;
      description = "UDP port to listen on";
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Address to bind to";
    };

    broadcastRate = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Broadcast rate limit (0 for unlimited)";
    };

    allowedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of allowed WireGuard public keys (empty allows all)";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the wpex port";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wpex;
      defaultText = "pkgs.wpex";
      description = "The wpex package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.wpex = {
      description = "wpex WireGuard Packet Relay";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart =
          let
            args = [
              "${cfg.package}/bin/wpex"
            ]
            ++ [
              "-port"
              (toString cfg.port)
            ]
            ++ lib.optionals (cfg.bind != "") [
              "-bind"
              cfg.bind
            ]
            ++ lib.optionals (cfg.broadcastRate != 0) [
              "-broadcast-rate"
              (toString cfg.broadcastRate)
            ]
            ++ lib.concatMap (key: [
              "-allow"
              key
            ]) cfg.allowedKeys;
          in
          lib.escapeShellArgs args;
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
