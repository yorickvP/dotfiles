{
  imports = [
    ../../services/backup.nix
  ];

  services.borgbackup.jobs.backup = {
    failOnWarnings = false;
    paths = [
      "/home"
      "/root"
      "/var/lib"
    ];
  };
}
