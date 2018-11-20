{ config, pkgs, lib, ... }:

{
  imports =
    [ <yori-nix/physical/xps9360.nix>
      <yori-nix/roles/workstation.nix>
    ];


  system.stateVersion = "17.09";

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --dpi 192
  '';
}
