{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./3950x-hardware-config.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd
  ];

  hardware.enableRedistributableFirmware = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelModules = [ "nct6775" "i2c-dev" "i2c-piix4" ];
  boot.kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;
  networking.hostId = "c7736638";
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  hardware.bluetooth.enable = true;

  networking.useDHCP = false;
  networking.usePredictableInterfaceNames = false;
  networking.bridges.br0.interfaces = [ "eth0" ];
  networking.interfaces.br0.useDHCP = true;
  # systemd.network.links."98-namepolicy" = {
  #   matchConfig.OriginalName = "*";
  #   linkConfig.NamePolicy = "mac kernel database onboard slot path";
  # };
  environment.systemPackages = [ pkgs.openrgb pkgs.egl-wayland ];
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];
  hardware.nvidia.powerManagement.finegrained = true;
  hardware.nvidia.prime.offload.enable = true;
  hardware.nvidia.prime = {
    nvidiaBusId = "PCI:5:0:0";
    amdgpuBusId = "PCI:15:0:0";
  };
  hardware.cpu.amd = {
    ryzen-smu.enable = true;
    updateMicrocode = true;
  };
}
