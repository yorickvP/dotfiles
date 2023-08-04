{ config, lib, pkgs, inputs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.common-cpu-intel ];
  hardware.enableRedistributableFirmware = true;

  boot.initrd.availableKernelModules =
    [ "nvme" "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { path = "/boot1"; devices = [ "nodev" ]; }
      { path = "/boot2"; devices = [ "nodev" ]; }
    ];
  };

  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/ba95c638-f243-48ee-ae81-0c70884e7e74";
  #   fsType = "ext4";
  #   options = [ "defaults" "relatime" "discard" ];
  # };

  swapDevices = [{ device = "/dev/disk/by-label/ssd-swap"; }];

  fileSystems."/data" = {
    device = "frumar-new";
    fsType = "zfs";
  };

  fileSystems."/data/plexmedia" = {
    device = "frumar-new/plexmedia";
    fsType = "zfs";
  };

  fileSystems."/boot1" = {
    device = "/dev/disk/by-label/EFI1";
    fsType = "vfat";
  };

  fileSystems."/boot2" = {
    device = "/dev/disk/by-label/EFI2";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "ssdpool/root";
    fsType = "zfs";
  };

  fileSystems."/var" = {
    device = "ssdpool/root/var";
    fsType = "zfs";
  };

  fileSystems."/torrent" = {
    device = "ssdpool/torrent";
    fsType = "zfs";
  };

  nix.settings.max-jobs = 4;
  services.avahi.allowInterfaces = [ "enp2s0" ];
}
  ## disk layout
  # 1x SATA Samsung 850 Evo, 250GB (old ssd)
  # - 248GB  root ext4
  # - 1.9GB  swap
  # - 0.1GB  bios_grub
  # 3x SATA WDC WD100EMAZ-00WJTA0, 10.0TB
  # - 9.1TiB zfs, frumar-new
  # - 8MiB   empty
  # 1x nvme Corsair Force MP510, 960G
  # - 2 GiB  "EFI1"     boot, ESP
  # - 858GB  "ssdpart1" zfs, ssdpool
  # - 100GB  "buf1"     empty, future use (metadata device?)
  # 1x nvme Samsung Evo 980, 1000G
  # - 2GiB   "EFI2"     boot, ESP
  # - 858GB  "ssdpart2" zfs, ssdpool
  # - 100GB  "buf2"     empty, future use (metadata device?)
  # - 8GiB   "swap"     swap
  # - 31.4GB "scratch"  empty, future use
  ## zfs layout
  ### frumar-new
  # frumar-new: 30T, 20T usable, mountpoint=/data, snapshotted
  # frumar-new/backup, mount=none
  # frumar-new/backup/blackadder, mount=none
  #   znapzends from blackadder:rpool/home-enc, encrypted and compressed at-rest there
  # frumar-new/plexmedia, mountpoint=/data/plexmedia, snapshotted, different blocksize
  ### ssdpool
  # ssdpool: 858G
  # ssdpool/root: compressed
  # ssdpool/root/var: compressed, snapshotted
  # ssdpool/torrent: not compressed, not snapshottend

