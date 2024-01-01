{
  documentation.nixos.enable = false;
  services.sshguard.enable = true;
  programs.mosh.enable = true;

  # environment.noXlibs = true;
  networking.firewall.logRefusedConnections =
    false; # Silence logging of scanners and knockers

  nix.settings.allowed-users = [ "@wheel" ];
  # TODO: upstream with noXlibs
  nixpkgs.overlays = [
    (self: super: {
      libdecor = null;
      imagemagick = super.imagemagick.override {
        libheifSupport = false;
        ghostscript = super.ghostscript.override {
          cupsSupport = false;
        };
      };
    })
  ];
}
