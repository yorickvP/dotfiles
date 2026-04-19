{ pkgs, ... }:
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };
  home.file.".gnupg/gpg.conf".text = ''
    no-greeting
    require-cross-certification
    charset utf-8
    keyserver hkps://keys.openpgp.org
    #keyserver-options auto-key-retrieve
  '';
}
