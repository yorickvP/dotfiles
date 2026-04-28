{ lib, options, ... }:

{
  documentation.nixos.enable = false;
  services.sshguard.enable = true;
  programs.mosh.enable = true;

  networking.firewall.logRefusedConnections = false; # Silence logging of scanners and knockers

  nix.settings.allowed-users = [ "@wheel" ];
  # save some space; skip when read-only.nix is active (it forbids module-side
  # overlay contributions — those machines apply the overlay at pkgs construction).
  nixpkgs.overlays = lib.mkIf (options.nixpkgs.overlays.type.name == "listOf") [
    (import ./server-pkgs-overlay.nix)
  ];
}
