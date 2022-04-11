{ config, pkgs, lib, ... }:
let sources = import ../../nix/sources.nix;
in {
  imports = [
    ./.
    "${sources.nixos-hardware}/lenovo/thinkpad/x1"
    ./x11-hardware-config.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.requestEncryptionCredentials = true;

  boot.supportedFilesystems = [ "zfs" ];
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
