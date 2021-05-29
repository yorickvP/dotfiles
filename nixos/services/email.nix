{ config, pkgs, lib, ... }:
let
  sources = import ../../nix/sources.nix;
in
{
  imports = [
    ("${sources.nixos-mailserver}")
  ];

  mailserver = rec {
    enable = true;
    fqdn = "pennyworth.yori.cc";
    domains = [ "yori.cc" "yorickvanpelt.nl" ];
    loginAccounts = {
      "yorick@yori.cc" = {
        hashedPassword = (import ../secrets.nix).yorick_mailPassword;
        catchAll = domains;
        aliases = [ "@yori.cc" "@yorickvanpelt.nl" ];
      };
    };
    certificateScheme = 3;
    enableImapSsl = true;
  };

  services.borgbackup.jobs.backup.paths = [ "/var/vmail" ];
}
