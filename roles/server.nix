{
  imports = [ ./. ];
  
  documentation.nixos.enable = false;
  services.sshguard.enable = true;
  programs.mosh.enable = true;

  environment.noXlibs = true;
  networking.firewall.logRefusedConnections = false; # Silence logging of scanners and knockers

}
