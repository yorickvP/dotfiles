{ config, pkgs, lib, ... }:
{
  imports =
    [ ../physical/3950x.nix
      ../roles/workstation.nix
    ];

  system.stateVersion = "19.09";

  yorick.lumi-vpn = {
    name = "yorick-homepc";
    mtu = 1408;
  };
  environment.systemPackages = [ pkgs.spice_gtk ];
  security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper";
  virtualisation.virtualbox.host.enable = lib.mkForce true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  users.users.yorick.extraGroups = [ "vboxusers" ];

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

  services.znapzend = {
    enable = true;
    pure = true;
    features = {
      zfsGetType = true;
      sendRaw = true;
    };
    zetup = {
      "rpool/home-enc" = {
        plan = "1d=>1h,1m=>1w";
        destinations.frumar = {
          host = "root@192.168.178.37";
          dataset = "frumar-new/backup/blackadder";
          plan = "1w=>1d,1y=>1w,10y=>1m,50y=>1y";
        };
      };
    };
  };
}
