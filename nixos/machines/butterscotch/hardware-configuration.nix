{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "rpool/nixos";
    fsType = "zfs";
  };
  fileSystems."/home" = {
    device = "rpool/home";
    fsType = "zfs";
  };
  fileSystems."/var" = {
    device = "rpool/nixos/var";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E790-4F42";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
      "umask=0077"
    ];
  };
  fileSystems."/var/models" = {
    device = "rpool/models";
    fsType = "zfs";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/63aa06bb-dde9-4805-a1ee-41bc54126601"; }
  ];

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp191s0";
    DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
