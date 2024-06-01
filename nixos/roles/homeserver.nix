{ lib, ... }: {
  users.users.lars = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = with (import ../sshkeys.nix); lars;
  };
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
