# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
let
  withSSL =
    x:
    {
      forceSSL = true;
      useACMEHost = "wildcard.yori.cc";
    }
    // x;
in

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hetznercloud.nix
    ../../roles/server.nix
    ../../services/backup.nix
    ../../services/email.nix
    inputs.yobot.nixosModules.default
  ];

  services.borgbackup.jobs.backup.paths = [
    "/home"
    "/root"
    "/var/lib"
  ];
  system.stateVersion = "19.03";

  services.yorick = {
    cert."wildcard.yori.cc".enable = true;
    public = {
      enable = true;
      vhost = "pub.yori.cc";
      nginx = withSSL { };
    };
    website = {
      enable = true;
      vhost = "yorickvanpelt.nl";
      nginx = {
        enableACME = true;
        forceSSL = true;
      };
    };
    git = {
      enable = true;
      vhost = "git.yori.cc";
      nginx = withSSL { };
    };
    muflax-church = {
      enable = true;
      vhost = "muflax.church";
    };
    calibre-web = {
      enable = true;
      vhost = "calibre.yori.cc";
      nginx = withSSL { };
    };
    vpn-host.enable = true;
  };

  age.secrets.muflax.file = ../../../secrets/http.muflax.age;
  services.muflax-blog = {
    enable = true;
    web-server = {
      port = 9001;
    };
    hidden-service = {
      hostname = "muflax65ngodyewp.onion";
      private_key = config.age.secrets.muflax.path;
    };
  };
  services.nginx = {
    enable = true;
    commonHttpConfig = "access_log off;";
    virtualHosts = {
      "yori.cc" = withSSL {
        globalRedirect = "yorickvanpelt.nl";
      };
      "yorickvanpelt.nl".locations."/p1".return = "301 https://git.yori.cc/yorick/meterkast";
      "pub.yori.cc".locations."/muflax/".extraConfig = ''
        rewrite ^/muflax/(.*)$ https://alt.muflax.church/$1 permanent;
      '';
      "recepten.yori.cc" = withSSL {
        locations."/".proxyPass = "http://127.0.0.1:8003";
      };

      "actual.yori.cc" = withSSL {
        locations."/" = {
          proxyPass = "http://[::1]:8004";
          #proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 64M;
          '';
        };
      };
    };
  };

  # TODO: reload cert in weechat
  security.acme.certs."pennyworth.yori.cc".postRun = ''
    cat fullchain.pem key.pem > /home/yorick/.weechat/ssl/relay.pem
    chown yorick:users /home/yorick/.weechat/ssl/relay.pem
    chmod 0600 $_
  '';

  users.users.yorick.packages = with pkgs; [
    sshfs-fuse
    weechat
    ripgrep
  ];
  networking.firewall.allowedTCPPorts = [ 60307 ]; # weechat relay

  age.secrets.yobot.file = ../../../secrets/yobot.toml.age;
  services.yobot = {
    enable = true;
    configFile = config.age.secrets.yobot.path;
  };
  services.play-nijmegen-calendar.enable = true;
  services.actual = {
    enable = true;
    settings = {
      hostname = "::1";
      port = 8004;
      allowedLoginMethods = [ "password" ];
      trustedProxies = [ "::1" ];
    };
  };
  security.acme.certs."wildcard.yori.cc".extraDomainNames = [ "yori.cc" ];
}
