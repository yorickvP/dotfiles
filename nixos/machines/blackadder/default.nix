{
  pkgs,
  ...
}:
{
  imports = [
    ../../roles/workstation.nix
  ];

  system.stateVersion = "19.09";

  users.users.judith.isNormalUser = true;

  # docker
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
  };
  virtualisation.oci-containers.backend = "docker";
  users.users.yorick.extraGroups = [ "docker" ];

  nix.optimise.automatic = true;

  yorick.dk-vpn = {
    enable = true;
    ip = "10.100.0.4";
  };
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_16;
    extensions = ps: [ ps.pgvector ];
    ensureDatabases = [ "hackerdeck" ];
    ensureUsers = [
      {
        name = "hackerdeck";
        ensureDBOwnership = true;
      }
    ];
    # ensureDatabases = [ "vierkantle" ];
    # ensureUsers = [
    #   {
    #     name = "vierkantle";
    #     ensureDBOwnership = true;
    #   }
    # ];
  };
  # allow gpg agent forwarding
  services.openssh.settings.StreamLocalBindUnlink = true;
  virtualisation.waydroid.enable = true;
  virtualisation.libvirtd.enable = true;
}
