let
  sshkeys = import ../../sshkeys.nix;
in
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
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.zfs.package = pkgs.zfs_2_4;

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
    "ttm.pages_limit=29360128"
    "ttm.page_pool_size=29360128" # 112GiB
  ];

  users.users = {
    judith = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshkeys.judith;
      packages = with pkgs; [
        uv
        git
        cmake
        gnumake
        gcc
        screen
        vim
      ];
      # packages = with pkgs; [
      #   git cmake gnumake gcc python3 python3.pkgs.pip screen vim
      # ];
      extraGroups = [ "video" ];
    };
  };
}
