{ lib, ... }:
{
  networking.firewall.logRefusedConnections = lib.mkForce true;
}
