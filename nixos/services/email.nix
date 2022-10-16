{ config, pkgs, lib, inputs, ... }:
{
  imports = [ inputs.nixos-mailserver.nixosModule ];
  age.secrets.yorick-mail-pass.file = ../../secrets/yorick-mail-pass.age;

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
    };
    certificateScheme = 3;
    enableImapSsl = true;
  };

  services.borgbackup.jobs.backup.paths = [ "/var/vmail" ];
}
