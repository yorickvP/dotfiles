{
  lib,
  ...
}:

{
  imports = [
    ../../roles/server.nix
    ../../roles/homeserver.nix
  ];

  system.stateVersion = "24.11";
  networking.hostId = "8425e349";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  age.secrets.msmtp-mail-pass.file = ../../../secrets/kirei-mail-pass.age;

  programs.msmtp.enable = true;
  services.smartd = {
    enable = true;
    defaults.autodetected = "-n standby"; # don't spin up drives
  };
  boot.zfs.extraPools = [ "zpool" ];
  boot.zfs.requestEncryptionCredentials = false;
  age.secrets.root-user-pass.file = lib.mkForce ../../../secrets/kirei-root-user-pass.age;
}
