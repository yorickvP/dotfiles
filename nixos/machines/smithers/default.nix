{
  pkgs,
  ...
}:

{
  imports = [
    ../../roles/workstation.nix
  ];

  system.stateVersion = "21.05";
  services.flatpak.enable = true;

  yorick.dk-vpn = {
    enable = true;
    ip = "10.100.0.6";
  };
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  environment.systemPackages = [ pkgs.yscripts.backup-laptop ];
}
