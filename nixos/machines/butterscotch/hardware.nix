{
  pkgs,
  inputs,
  ...
}:

let
  # robcohen's nix-amd-npu pins XRT to tag 202610.2.21.21, but its only
  # published amdxdna plugin (xdna-driver 2.21.75) is written against an XRT
  # 103 commits newer — it references query::aie_coredump, absent from the
  # pinned XRT headers, so the plugin fails to compile. Rebuild the XRT chain
  # against the exact XRT commit xdna-driver 2.21.75's submodule points at, so
  # xrt, the plugin's compile-time headers, and the plugin's linked lib agree.
  npupkgs = import inputs.nixpkgs-vitis-ai {
    inherit (pkgs.stdenv.hostPlatform) system;
    overlays = [
      (_final: prev: {
        xrt = prev.xrt.overrideAttrs (_: {
          src = xrtSrc;
        });
        xrt-plugin-amdxdna = prev.xrt-plugin-amdxdna.overrideAttrs (_: {
          inherit xrtSrc;
        });
      })
    ];
  };
  xrtSrc = pkgs.fetchFromGitHub {
    owner = "Xilinx";
    repo = "XRT";
    rev = "4eb1f4392a012b4e6eca759762389c612537f7c7";
    hash = "sha256-sujiSRZuIelhvUew7yeCfApAmp/Pf2+F38KO9cxI2HE=";
    fetchSubmodules = true;
  };
  inherit (npupkgs) xrt-amdxdna;
in

{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
    inputs.nix-amd-npu.nixosModules.default
  ];

  services.power-profiles-daemon.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "d05ee74c";

  boot.zfs.package = pkgs.zfs_2_4;

  boot.kernelParams = [
    #"ttm.pages_limit=25165824" "ttm.page_pool_size=25165824" # 96GiB
    "ttm.pages_limit=29360128"
    "ttm.page_pool_size=29360128" # 112GiB
  ];
  hardware.amd-npu.enable = true;
  hardware.amd-npu.package = xrt-amdxdna;
}
