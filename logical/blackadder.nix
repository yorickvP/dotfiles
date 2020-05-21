{ config, pkgs, lib, ... }:
{
  imports =
    [ ../physical/3950x.nix
      ../roles/workstation.nix
    ];

  nixpkgs.overlays = [ (import (builtins.fetchTarball https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz)) ];
  system.stateVersion = "19.09";

  networking.wireguard.interfaces = {
    wg-lumi = {
      privateKeyFile = "/home/yorick/engineering/lumi/secrets/devel/vpn/wg/workstations.yorick-homepc.key";
      ips = [ "10.109.0.18" ];
      peers = [ {
        publicKey = "6demp+PX2XyVoMovDj4xHQ2ZHKoj4QAF8maWpjcyzzI=";
        endpoint = "wg.lumi.guide:31727";
        allowedIPs = [ "10.96.0.0/12" "10.0.12.0/22" "10.0.1.0/26" ];
      }];
      postSetup = "ip link set dev wg-lumi mtu 1408";
    };
  };

  # development
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_10;
  };
  # users.users.pie = {
  #   isNormalUser = true;
  #   openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDpj2GrPpXtAp9Is0wDyQNl8EQnBiITkSAjhf7EjIqX" ];
  # };
  # services.nfs.server = {
  #   enable = true;
  #   exports = ''
  #     /export 10.40.0.0/24(insecure,rw,sync,no_subtree_check,crossmnt,fsid=0,no_root_squash)
  #     /export/nfs/client1 10.40.0.0/24(insecure,rw,sync,no_subtree_check,crossmnt,all_squash,anonuid=0,anongid=0,no_root_squash)
  #     /export/nfs/client1/nix 10.40.0.0/24(insecure,ro,sync,no_subtree_check,crossmnt)
  #   '';
  # };
}
