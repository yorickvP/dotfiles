{ config, lib, pkgs, ... }:
let sources = import ../nix/sources.nix;
in
{
  imports = [
    "${sources.nixos-hardware}/dell/xps/13-9360"
    ./xps9360-hardware-config.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "i8k" ];
  boot.extraModprobeConfig = ''
    options i8k ignore_dmi=1
  '';
  fileSystems."/".options = ["defaults" "relatime" "discard"];

  boot.initrd.luks.devices."nix-crypt".allowDiscards = true;

  services.undervolt = rec {
    enable = true;
    coreOffset = -50;
    gpuOffset = -50;
    uncoreOffset = -50;
    analogioOffset = -50;
  };
  services.tlp.settings = {
    "CPU_SCALING_GOVERNOR_ON_AC" = "performance";
    "CPU_SCALING_GOVERNOR_ON_BAT" = "powersave";
  };
  services.logind.lidSwitch = "ignore";

  services.xserver.libinput.enable = true;

  networking.wireless = {
    enable = false;
    iwd.enable = true;
  };
  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;

  services.udev.packages = [ pkgs.crda ];
  hardware.firmware = [ pkgs.wireless-regdb ];
  # gotta go faster
  networking.dhcpcd.extraConfig = ''
    noarp
  '';
}
