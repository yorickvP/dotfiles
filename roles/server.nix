{
  imports = [ <yori-nix/roles> ];
  
  services.nixosManual.enable = false;
  services.sshguard.enable = true;

  environment.noXlibs = true;
  networking.firewall.logRefusedConnections = false;    # Silence logging of scanners and knockers

}
