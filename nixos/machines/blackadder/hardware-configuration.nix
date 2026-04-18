{
  lib,
  ...
}:

{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "rpool/root/nixos";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rpool/home-enc";
    fsType = "zfs";
  };
  fileSystems."/home/yorick/steam-games" = {
    device = "dpool/steam";
    fsType = "zfs";
  };
  fileSystems."/home/yorick/VirtualBox VMs" = {
    device = "dpool/virtualbox-vms";
    fsType = "zfs";
  };
  fileSystems."/var/lib/docker" = {
    device = "dpool/docker";
    fsType = "zfs";
  };
  fileSystems."/var/lib/libvirt" = {
    device = "dpool/libvirt";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    # device = "/dev/disk/by-uuid/5D0A-7902"; # mp600
    device = "/dev/disk/by-uuid/897D-8245"; # 980pro
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/61a23e27-2cd4-4456-bcde-aec68be04239"; } # mp600
    { device = "/dev/disk/by-uuid/15057589-6483-4e10-9f87-67ed7e314d26"; } # 980pro
  ];

  nix.settings.max-jobs = lib.mkDefault 32;
  # High-DPI console
  #i18n.consoleFont = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  zramSwap = {
    enable = true;
    memoryPercent = 15;
  };
}
