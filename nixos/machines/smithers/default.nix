{ config, pkgs, lib, ... }:

{
  imports = [ ./x11.nix ../../roles/workstation.nix ];

  yorick.lumi-vpn.enable = lib.mkForce false;
  yorick.lumi-cache.enable = lib.mkForce false;

  system.stateVersion = "21.05";
  services.flatpak.enable = true;
}
