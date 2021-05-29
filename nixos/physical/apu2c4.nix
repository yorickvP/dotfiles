# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "ehci_pci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1396f814-6cc2-4988-992a-3558fa1ac5a2";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/5f8f358d-f63c-48ad-a322-d1aeb403e4ff"; }];

  nix.maxJobs = lib.mkDefault 4;
}
