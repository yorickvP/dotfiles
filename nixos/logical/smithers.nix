# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let sources = import ../../nix/sources.nix;
in {
  imports =
    [ # Include the results of the hardware scan.
      "${sources.nixos-hardware}/lenovo/thinkpad/x1"
      ../physical/x11-hardware-config.nix
      ../roles/workstation.nix

    ];
  yorick.lumi-vpn.enable = lib.mkForce false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.requestEncryptionCredentials = true;

  networking.hostName = "smithers";
  networking.wireless.iwd.enable = true;
  networking.hostId = "54a8968e";

  hardware.bluetooth.enable = true;
  services.fprintd.enable = true;
  system.stateVersion = "21.05";
  boot.kernelPackages = pkgs.linuxPackages_latest; # new hardware

  boot.initrd.availableKernelModules = [ "i915" ];
  boot.loader.timeout = 0;
  boot.kernelParams = ["i915.fastboot=1" "quiet"];
  #boot.plymouth.enable = true;
}
