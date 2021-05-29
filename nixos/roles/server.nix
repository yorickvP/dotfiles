{
  imports = [ ./. ];

  documentation.nixos.enable = false;
  services.sshguard.enable = true;
  programs.mosh.enable = true;

  environment.noXlibs = true;
  networking.firewall.logRefusedConnections =
    false; # Silence logging of scanners and knockers
  # TODO: upstream with noXlibs
  # https://github.com/NixOS/nixpkgs/pull/107394
  nixpkgs.overlays = [
    (self: super: {
      elixir_1_8 =
        (self.beam.packagesWith (self.beam.interpreters.erlang_nox)).elixir_1_8;
      erlang = super.erlang_nox;
    })
  ];
}
