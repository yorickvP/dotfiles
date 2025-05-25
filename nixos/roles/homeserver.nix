{ lib, ... }: {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
  networking.firewall.logRefusedConnections = lib.mkForce true;
}
