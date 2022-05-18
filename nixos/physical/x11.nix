{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./.
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1
    ./x11-hardware-config.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.requestEncryptionCredentials = true;

  boot.supportedFilesystems = [ "zfs" ];
  # FIXME: https://bugzilla.kernel.org/show_bug.cgi?id=215768
  #boot.kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  networking.wireless.iwd.enable = true;
  networking.hostId = "54a8968e";

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  hardware.bluetooth.enable = true;
  services.fprintd.enable = true;

  boot.initrd.availableKernelModules = [ "i915" ];
  boot.loader.timeout = 1;
  boot.kernelParams = [ "i915.fastboot=1" ];
  #boot.plymouth.enable = true;
}
