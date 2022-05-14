{ config, pkgs, lib, ... }:
let sources = import ../../nix/sources.nix;
in {
  imports = [
    ./.
    ./3950x-hardware-config.nix
    "${sources.nixos-hardware}/common/cpu/amd"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelModules = [ "nct6775" ];
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
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
    "amdgpu.noretry=0"
    "amdgpu.lockup_timeout=1000"
    "amdgpu.gpu_recovery=1"
    "amdgpu.audio=0"
    # thunderbolt
    "pcie_ports=native"
    "pci=assign-busses,hpbussize=0x33,realloc"
  ];
}
