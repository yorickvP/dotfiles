{ config, lib, pkgs, modulesPath, ... }:
let ipconf = (import ../../secrets.nix).ipconf.${config.networking.hostName};
in {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules =
    [ "ata_piix" "uhci_hcd" "virtio_pci" "sd_mod" "sr_mod" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nix.settings.max-jobs = lib.mkDefault 1;
  #services.nscd.enable = false;
  networking.dhcpcd.enable = false;
  systemd.network.enable = true;
  systemd.network.networks."40-hetzner" = {
    DHCP = "ipv4";
    address = [ ipconf.mainIPv6 ];
    gateway = [ "fe80::1" ];
    matchConfig.Name = "ens3";
  };
  services.fstrim.enable = true;
}
