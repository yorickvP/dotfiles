# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../physical/x11-hardware-config.nix
      ../roles/workstation.nix

    ];
  yorick.lumi-vpn.enable = lib.mkForce false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.requestEncryptionCredentials = true;

  networking.hostName = "smithers"; # Define your hostname.
  networking.wireless.iwd.enable = true;
  networking.hostId = "54a8968e";

  system.stateVersion = "21.05"; # Did you read the comment?
  boot.kernelPackages = pkgs.linuxPackages_latest; # new hardware

}
