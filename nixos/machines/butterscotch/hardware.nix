{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
    inputs.nix-amd-npu.nixosModules.default
  ];

  services.power-profiles-daemon.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "d05ee74c";

  # TODO(26.05): bump
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.zfs.package = pkgs.zfs_2_4;

  boot.kernelParams = [
    #"ttm.pages_limit=25165824" "ttm.page_pool_size=25165824" # 96GiB
    "ttm.pages_limit=29360128"
    "ttm.page_pool_size=29360128" # 112GiB
  ];
  hardware.amd-npu.enable = true;
}
