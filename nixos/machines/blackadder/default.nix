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
  };
  virtualisation = {
    waydroid.enable = true;
    libvirtd.enable = true;
    docker = {
      enable = true;
      storageDriver = "overlay2";
    };
    oci-containers.backend = "docker";
  };
  services.tumbler.enable = true;
  programs.thunar.enable = true;
  programs.thunar.plugins = [ pkgs.xfce.thunar-archive-plugin ];
  services.gvfs.enable = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.binfmt.preferStaticEmulators = true;

}
