{
  documentation.nixos.enable = false;
  services.sshguard.enable = true;
  programs.mosh.enable = true;

  environment.noXlibs = true;
  networking.firewall.logRefusedConnections =
    false; # Silence logging of scanners and knockers

  # TODO: upstream with noXlibs
  nixpkgs.overlays = [
    (self: super: {
      libdecor = null;
    })
  ];
}
