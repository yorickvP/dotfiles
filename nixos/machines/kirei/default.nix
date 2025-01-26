# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../roles/server.nix
    ];

  system.stateVersion = "24.11";
  networking.hostId = "8425e349";

  networking.firewall.logRefusedConnections = lib.mkForce true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "kirei"; # Define your hostname.

  age.secrets = {
    kirei-mail-pass.file = ../../../secrets/kirei-mail-pass.age;
  };

  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-01 02:00:00"; # monthly + 2 hours
  };
  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      tls = true;
      from = "kirei@yori.cc";
      host = "pennyworth.yori.cc";
      user = "kirei@yori.cc";
      passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.kirei-mail-pass.path}";
    };
  };
  services.smartd = {
    enable = true;
    notifications.mail = {
      enable = true;
      sender = "kirei@yori.cc";
      recipient = "yorickvanpelt@gmail.com";
    };
  };
  services.zfs.zed = {
    enableMail = true;
    settings = {
      ZED_EMAIL_ADDR = [ "yorickvanpelt@gmail.com" ];
      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };
  boot.zfs.extraPools = [ "zpool" ];
  boot.zfs.requestEncryptionCredentials = false;
  age.secrets.root-user-pass.file = lib.mkForce ../../../secrets/kirei-root-user-pass.age;
}
