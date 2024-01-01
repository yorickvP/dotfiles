{ config, lib, pkgs, ... }:

let cfg = config.services.yorick.vpn-host;
in {
  options.services.yorick.vpn-host = with lib; {
    enable = mkEnableOption "vpn-host";
  };
  config = lib.mkIf cfg.enable {

    services.prometheus.exporters.wireguard.enable = true;

    networking = {
      firewall = {
        allowedUDPPorts = [ 31790 ]; # wg
        interfaces.wg-y.allowedTCPPorts = [ 9586 ]; # wireguard exporter
      };
      wireguard.interfaces.wg-y.peers = let vpn = import ../vpn.nix;
      in lib.mkForce (lib.mapAttrsToList (machine: publicKey: {
        inherit publicKey;
        allowedIPs = [ "${vpn.ips.${machine}}/32" ];
      }) vpn.keys);
    };
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  };
}
