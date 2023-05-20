{ config, pkgs, lib, ... }: {
  imports = [ ./xps9360.nix ../../roles/workstation.nix ];

  system.stateVersion = "17.09";

  yorick.lumi-vpn = {
    name = "yorick";
    ip = "10.109.0.10";
  };
}
