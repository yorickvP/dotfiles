{ name, config, ... }:
{
  age.secrets.backup_repo.file = ../../secrets/${name}_borg_repo.age;
  age.secrets.backup_ssh.file = ../../secrets/${name}_borg_ssh.age;
  programs.ssh.knownHosts."zh3213.rsync.net".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJtclizeBy1Uo3D86HpgD3LONGVH0CJ0NT+YfZlldAJd";
  services.borgbackup.jobs.backup = {
    encryption = {
      # Keep the encryption key in the repo itself
      mode = "repokey-blake2";

      # Password is used to decrypt the encryption key from the repo
      passCommand = "cat ${config.age.secrets.backup_repo.path}";
    };
    environment = {
      # Make sure we're using Borg >= 1.0
      BORG_REMOTE_PATH = "borg14";

      # SSH key is specific to the subaccount defined in the repo username
      BORG_RSH = "ssh -i ${config.age.secrets.backup_ssh.path}";
    };

    # Define schedule
    startAt = "hourly";

    repo = "zh3213@zh3213.rsync.net:${name}";

    prune.keep = {
      # hourly backups for the past week
      within = "7d";

      # daily backups for two weeks before that
      daily = 14;

      # weekly backups for a month before that
      weekly = 4;

      # monthly backups for 6 months before that
      monthly = 6;

      # 2 years
      yearly = 2;
    };
  };
}
