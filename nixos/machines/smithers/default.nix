{ pkgs, ... }:

{
  imports = [
    ../../roles/workstation.nix
  ];

  system.stateVersion = "21.05";

  yorick.dk-vpn = {
    enable = true;
    ip = "10.100.0.6";
  };
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --cmd sway --time --remember";
  };
}
