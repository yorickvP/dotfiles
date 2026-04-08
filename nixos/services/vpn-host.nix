{
  config,
  lib,
  ...
}:

let
  cfg = config.services.yorick.vpn-host;
in
{
  options.services.yorick.vpn-host = with lib; {
    enable = mkEnableOption "vpn-host";
  };
  config = lib.mkIf cfg.enable {

    services.prometheus.exporters.wireguard.enable = true;

    networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 9586 ]; # wireguard exporter

    services.wg-restarter.enable = lib.mkForce false;
  };
}
