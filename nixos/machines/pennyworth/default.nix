# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }: {
  imports = [
    ./hetznercloud.nix
    ../../roles/server.nix
    ../../roles/datakami.nix
    ../../services/backup.nix
    ../../services/email.nix
  ];

  system.stateVersion = "19.03";

  services.yorick = {
    public = {
      enable = true;
      vhost = "pub.yori.cc";
    };
    website = {
      enable = true;
      vhost = "yorickvanpelt.nl";
    };
    git = {
      enable = true;
      vhost = "git.yori.cc";
    };
    muflax-church = {
      enable = true;
      vhost = "muflax.church";
    };
    calibre-web = {
      enable = true;
      vhost = "calibre.yori.cc";
    };
    vpn-host.enable = true;
  };

  age.secrets.muflax.file = ../../../secrets/http.muflax.age;
  services.muflax-blog = {
    enable = true;
    web-server = { port = 9001; };
    hidden-service = {
      hostname = "muflax65ngodyewp.onion";
      private_key = config.age.secrets.muflax.path;
    };
  };
  services.nginx = {
    enable = true;
    commonHttpConfig = "access_log off;";
    virtualHosts = {
      "yori.cc" = {
        enableACME = true;
        forceSSL = true;
        globalRedirect = "yorickvanpelt.nl";
      };
      "yorickvanpelt.nl".locations."/p1".return =
        "301 https://git.yori.cc/yorick/meterkast";
      "pub.yori.cc".locations."/muflax/".extraConfig = ''
        rewrite ^/muflax/(.*)$ https://alt.muflax.church/$1 permanent;
      '';
    };
  };

  # TODO: reload cert in weechat
  security.acme.certs."pennyworth.yori.cc".postRun = ''
    cat fullchain.pem key.pem > /home/yorick/.weechat/ssl/relay.pem
    chown yorick:users /home/yorick/.weechat/ssl/relay.pem
    chmod 0600 $_
  '';

  users.users.yorick.packages = with pkgs; [ sshfs-fuse weechat ripgrep ];
}
