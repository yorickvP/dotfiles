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
  boot.kernelPackages = pkgs.linuxPackages_6_17;
  # temp
  nixpkgs.overlays = [(self: super: {
    linux-firmware = super.linux-firmware.overrideAttrs (rec {
      version = "20251111";
      src = self.fetchFromGitLab {
        owner = "kernel-firmware";
        repo = "linux-firmware";
        tag = version;
        hash = "sha256-YGcG2MxZ1kjfcCAl6GmNnRb0YI+tqeFzJG0ejnicXqY=";
      };
    });
  })];

}
