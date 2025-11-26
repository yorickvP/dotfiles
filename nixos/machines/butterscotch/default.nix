{
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
  services.power-profiles-daemon.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "d05ee74c";

  system.stateVersion = "25.05";
  boot.kernelPackages = pkgs.linuxPackages_6_16;

}
