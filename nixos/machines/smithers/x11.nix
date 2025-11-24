{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
    ./x11-hardware-config.nix
  ];

  hardware.enableRedistributableFirmware = true;
  services.thermald.enable = true;
  services.thermald.ignoreCpuidCheck = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.requestEncryptionCredentials = true;

  boot.supportedFilesystems = [ "zfs" ];
  networking.wireless = {
    enable = false;
    iwd.enable = true;
  };
  networking.hostId = "54a8968e";

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  hardware.bluetooth.enable = true;
  services.fprintd.enable = true;
  hardware.intelgpu = {
    driver = "i915";
    vaapiDriver = "intel-media-driver";
    computeRuntime = "legacy";
  };

  boot = {
    # flickerfree
    initrd.systemd.enable = true;
    initrd.verbose = false;
    plymouth.enable = true;
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "i915.enable_guc=3"
    ];
  };
  boot.loader.timeout = 0;

  # networking.dhcpcd.extraConfig = "noarp";
  networking.interfaces.wlan0.useDHCP = false;
  networking.interfaces.wg-y.useDHCP = false;
  networking.interfaces.wg-dk.useDHCP = false;
  networking.wireless.iwd.settings = {
    General.EnableNetworkConfiguration = true;
    Network.NameResolvingService = "resolvconf";
    Network.RoutePriorityOffset = 2000;
  };
  zramSwap = {
    enable = true;
    memoryPercent = 30;
  };
}
