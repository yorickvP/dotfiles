{ config, lib, pkgs, ... }:
{
  imports = [
    "${import ./nixos-hardware.nix}/dell/xps/13-9360"
    ./xps9360-hardware-config.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "i915.enable_psr=0" ];
  fileSystems."/".options = ["defaults" "relatime" "discard"];

  boot.initrd.luks.devices."nix-crypt".allowDiscards = true;

  # intel huc, guc. qca6174 (older firmware)
  hardware.enableRedistributableFirmware = true;

  # hardware is thermal-limited
  services.thermald.enable = lib.mkDefault true;

  services.xserver.libinput.enable = true;

  networking.wireless.enable = true;
  hardware.bluetooth.enable = true;
  # gotta go faster
  networking.dhcpcd.extraConfig = ''
    noarp
  '';
}
