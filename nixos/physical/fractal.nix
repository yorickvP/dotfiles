{ config, lib, pkgs, ... }:
let sources = import ../../nix/sources.nix;
in
{
  imports =
    [ ./.
      "${sources.nixos-hardware}/common/cpu/intel"
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub = {
    enable = true;
    version = 2;
    # Define on which hard drive you want to install Grub.
    device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_250GB_S21PNXAG441016B";
  };


  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ba95c638-f243-48ee-ae81-0c70884e7e74";
      fsType = "ext4";
      options = ["defaults" "relatime" "discard"];
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/nixos-swap"; }
    ];
  fileSystems."/data" =
    { device = "frumar-new";
      fsType = "zfs";
    };

  fileSystems."/data/plexmedia" =
    { device = "frumar-new/plexmedia";
      fsType = "zfs";
    };

  nix.maxJobs = 4;
  services.avahi.interfaces = [ "enp2s0" ];
}
