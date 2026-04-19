{
  imports = [
    ../../services/backup.nix
  ];

  services.borgbackup.jobs.backup.paths = [
    "/home"
    "/root"
    "/var/lib"
  ];
}
