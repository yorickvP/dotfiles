{ config, pkgs, lib, ... }:
{
  imports =
    [ ../physical/xps9360.nix
      ../roles/workstation.nix
    ];

  nixpkgs.overlays = [ (import (builtins.fetchTarball https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz)) ];
  system.stateVersion = "17.09";

  networking.wireguard.interfaces = {
    wg-lumi = {
      privateKeyFile = "/home/yorick/engineering/lumi/secrets/devel/vpn/wg/workstations.yorick.key";
      ips = [ "10.109.0.10" ];
      peers = [ {
        publicKey = "6demp+PX2XyVoMovDj4xHQ2ZHKoj4QAF8maWpjcyzzI=";
        endpoint = "wg.lumi.guide:31727";
        allowedIPs = [ "10.96.0.0/12" "10.0.12.0/22" "10.0.1.0/26" ];
      }];
      postSetup = "ip link set dev wg-lumi mtu 1371";
    };
  };

  # development
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_10;
  };
}
