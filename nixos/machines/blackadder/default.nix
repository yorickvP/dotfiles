{
  pkgs,
  ...
}:
{
  imports = [
    ./3950x.nix
    ../../roles/workstation.nix
    ./microvm.nix
  ];

  system.stateVersion = "19.09";

  # backups
  services.znapzend = {
    enable = true;
    zetup = {
      "rpool/home-enc" = {
        plan = "1d=>1h,1m=>1w";
        destinations.frumar = {
          host = "znapzend-blackadder@frumar.home.yori.cc";
          dataset = "frumar-new/backup/blackadder";
          plan = "1w=>1d,1y=>1w,10y=>1m,50y=>1y";
        };
      };
    };
  };

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
