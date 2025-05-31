{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  rspamd-dqs = pkgs.fetchFromGitHub {
    owner = "spamhaus";
    repo = "rspamd-dqs";
    rev = "47bfe74222fda593e2fda7ef3243259c31d69ab9";
    hash = "sha256-fcnkbtxciDDguwlHHw6vyc8fxZUDBJEQHbpnUO5kclI=";
    postFetch = ''
      sed -i -e 's/your_DQS_key/{= env.dqs =}/g' $out/3.x/*.conf
    '';
  };
in
{
  imports = [ inputs.nixos-mailserver.nixosModule ];
  age.secrets.yorick-mail-pass.file = ../../secrets/yorick-mail-pass.age;
  age.secrets.frumar-mail-pass-hash.file = ../../secrets/frumar-mail-pass-hash.age;
  age.secrets.kirei-mail-pass-hash.file = ../../secrets/kirei-mail-pass-hash.age;
  age.secrets.rspamd-env.file = ../../secrets/rspamd-env.age;

  mailserver = rec {
    enable = true;
    fqdn = "pennyworth.yori.cc";
    domains = [
      "yori.cc"
      "yorickvanpelt.nl"
    ];
    loginAccounts = {
      "yorick@yori.cc" = {
        hashedPasswordFile = config.age.secrets.yorick-mail-pass.path;
        catchAll = domains;
        aliases = [
          "@yori.cc"
          "@yorickvanpelt.nl"
        ];
      };
      "frumar@yori.cc" = {
        hashedPasswordFile = config.age.secrets.frumar-mail-pass-hash.path;
        sendOnly = true;
      };
      "kirei@yori.cc" = {
        hashedPasswordFile = config.age.secrets.kirei-mail-pass-hash.path;
        sendOnly = true;
      };
    };
    certificateScheme = "acme-nginx";
    enableImapSsl = true;
  };

  services.borgbackup.jobs.backup.paths = [ "/var/vmail" ];
  services.rspamd = {
    extraConfig = ''
      spamhaus {
        dqs = "{= env.dqs =}"
        max_urls = 100
        max_cws = 100
      }
    '';
    locals."rbl.conf".source = "${rspamd-dqs}/3.x/rbl.conf";
    # https://github.com/spamhaus/rspamd-dqs/issues/31
    overrides."rbl_group.conf".source = "${rspamd-dqs}/3.x/rbl_group.conf";
  };
  systemd.services.rspamd.serviceConfig.EnvironmentFile = config.age.secrets.rspamd-env.path;
}
