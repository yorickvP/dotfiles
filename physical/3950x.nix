{ config, pkgs, lib, ... }:
let sources = import ../nix/sources.nix; 
in
{
  imports =
    [ ./.
      ./3950x-hardware-config.nix
      "${sources.nixos-hardware}/common/cpu/amd"
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelModules = [ "nct6775" ];
  boot.kernelPackages = pkgs.linuxPackages_5_9;
  networking.hostId = "c7736638";
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  hardware.bluetooth.enable = true;

  networking.useDHCP = false;
  networking.interfaces.enp9s0.useDHCP = true;
}
