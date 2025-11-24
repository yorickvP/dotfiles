{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../../roles/workstation.nix
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
  ];

  yorick.dk-vpn = {
    enable = true;
    ip = "10.100.0.7";
  };
  virtualisation.libvirtd.enable = lib.mkForce false;
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  # Use the systemd-boot EFI boot loader.
  hardware.enableRedistributableFirmware = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "d05ee74c";

  system.stateVersion = "25.05";
  boot.kernelPackages = pkgs.linuxPackages_6_16;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  hardware.bluetooth.enable = true;

}
