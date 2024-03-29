{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1
    ./x11-hardware-config.nix
  ];

  hardware.enableRedistributableFirmware = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.requestEncryptionCredentials = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;
  networking.wireless = {
    enable = false;
    iwd.enable = true;
  };
  networking.hostId = "54a8968e";

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  hardware.bluetooth.enable = true;
  services.fprintd.enable = true;

  boot = {
    initrd.availableKernelModules = [ "i915" ];
    # flickerfree
    initrd.systemd.enable = true;
    initrd.verbose = false;
    plymouth.enable = true;
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_level=3" "i915.fastboot=1" ];
  };
  boot.loader.timeout = 0;

  networking.dhcpcd.extraConfig = "noarp";
}
