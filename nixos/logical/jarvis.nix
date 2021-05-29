{ config, pkgs, lib, ... }: {
  imports = [ ../physical/xps9360.nix ../roles/workstation.nix ];

  system.stateVersion = "17.09";

  yorick.lumi-vpn.name = "yorick";
}
