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

  services.znapzend = {
    enable = true;
    zetup = {
      "rpool/home" = {
        plan = "1d=>1h,1m=>1w";
      };
      "rpool/nixos/var" = {
        plan = "1d=>1h,1m=>1w";
      };
    };
  };
  boot.kernelParams = [
    #"ttm.pages_limit=25165824" "ttm.page_pool_size=25165824" # 96GiB
    "ttm.pages_limit=29360128" "ttm.page_pool_size=29360128" # 112GiB
  ];
}
