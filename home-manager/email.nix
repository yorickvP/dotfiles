{ lib, pkgs, options, config, ... }:
{

  imports = [./accounts-email.nix];
  disabledModules = ["accounts/email.nix"];
  config = {
    programs.neomutt = {
      enable = true;
      settings = {
        auto_tag = "yes";
        crypt_reply_sign = "yes";
        delete = "ask-yes";
        imap_passive = "no";
        mail_check = "60";
        sort_aux = "reverse-last-date-received";
        sort_browser = "date";
        edit_headers = "yes";
        implicit_autoview = "no";
      };
      binds = [
        { map = "index"; key = "G"; action = "imap-fetch-mail"; }
        { map = "pager"; key = "<up>"; action = "previous-line"; }
        { map = "pager"; key = "<down>"; action = "next-line"; }
      ];
      
      extraConfig = "source ${./mutt-colors}";
    };
    xdg.configFile."neomutt/neomuttrc".text = lib.mkBefore ''
        set imap_user = "yorick@yori.cc"
        set imap_pass = "`pass sysadmin/yori.ccMail | head -n1`"
    '';
    accounts.email.accounts = {
      yori-cc = rec {
        primary = true;
        userName = "yorick@yori.cc";
        passwordCommand = "pass sysadmin/yori.ccMail | head -n1";
        realName = "Yorick van Pelt";
        address = "Yorick van Pelt <yorick@yorickvanpelt.nl>";
        imap.host = "pennyworth.yori.cc";
        smtp.host = "pennyworth.yori.cc";
        gpg.key = "6EFD1053ADB6ABF50DF64792A36E70F9DC014A15";
        neomutt.enable = true;
        neomutt.extraMailboxes = [ "Archive" "Sent" "Spam" "Trash" ];
        neomutt.extraConfig = ''
          set pgp_sign_as = "${gpg.key}"
        '';
        maildir.absPath = "imaps://pennyworth.yori.cc";
        folders = {
          inbox = "INBOX";
          trash = "Archive";
        };
      };
    };
  };
}

