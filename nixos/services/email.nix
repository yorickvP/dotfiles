{ config, pkgs, lib, inputs, ... }:
{
  imports = [ inputs.nixos-mailserver.nixosModule ];
  age.secrets.yorick-mail-pass.file = ../../secrets/yorick-mail-pass.age;
  age.secrets.frumar-mail-pass-hash.file = ../../secrets/frumar-mail-pass-hash.age;

  mailserver = rec {
    enable = true;
    fqdn = "pennyworth.yori.cc";
    domains = [ "yori.cc" "yorickvanpelt.nl" ];
    loginAccounts = {
      "yorick@yori.cc" = {
        hashedPasswordFile = config.age.secrets.yorick-mail-pass.path;
        catchAll = domains;
        aliases = [ "@yori.cc" "@yorickvanpelt.nl" ];
      };
      "frumar@yori.cc" = {
        hashedPasswordFile = config.age.secrets.frumar-mail-pass-hash.path;
        sendOnly = true;
      };
    };
    certificateScheme = "acme-nginx";
    enableImapSsl = true;
  };

  services.borgbackup.jobs.backup.paths = [ "/var/vmail" ];
}
