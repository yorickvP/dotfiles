{
  config,
  pkgs,
  lib,
  ...
}:
let
  vpnCfg = config.services.yorick.torrent-vpn;
in
{
  users.users.torrent = {
    isSystemUser = true;
    createHome = false;
    group = "torrent";
    home = "/torrent";
  };
  users.groups.torrent = { };
  systemd.tmpfiles.rules = [
    "d /torrent 771 torrent torrent"
  ];
  users.users.yorick.extraGroups = [ "torrent" ];

  services.yorick.torrent-vpn = {
    enable = true;
    name = "mullvad-nl4";
    namespace = "torrent";
  };
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.plex.after = [ "data-plexmedia.mount" ];
  services.sonarr = {
    enable = true;
    group = "plex";
    user = "plex";
  };
  services.radarr = {
    enable = true;
    group = "plex";
    user = "plex";
  };
  users.users.plex.packages = with pkgs; [
    ffmpeg
  ];
  users.users.yorick.packages = with pkgs; [
    yscripts.absorb
    ffmpeg
    pkgs.transmission_4
  ];
  services.transmission = {
    enable = true;
    home = "/torrent";
    user = "torrent";
    group = "torrent";
    package = pkgs.transmission_4;
    webHome = pkgs.flood-for-transmission;
    settings = {
      # https://github.com/transmission/transmission/blob/main/docs/Editing-Configuration-Files.md
      anti-brute-force-enabled = true;
      bind-address-ipv4 = vpnCfg.ipv4;
      bind-address-ipv6 = vpnCfg.ipv6;
      cache-size-mb = 64;
      incomplete-dir = "/torrent/incomplete";
      incomplete-dir-enabled = true;
      message-level = 3;
      peer-port = 55632;
      port-forwarding-enabled = false;
      rename-partial-files = false;
      rpc-authentication-required = true;
      rpc-bind-address = "unix:/torrent/sockets/transmission.sock";
      rpc-enabled = true;
      rpc-username = "admin";
      rpc-socket-mode = "0722";
    };
    credentialsFile = config.age.secrets.transmission-rpc.path;
  };
  age.secrets.transmission-rpc.file = ../../../secrets/transmission-rpc.age;
  systemd.services.transmission = {
    serviceConfig = {
      BindReadOnlyPaths = [
        "/etc/netns/torrent/resolv.conf:/etc/resolv.conf:norbind"
        "/data/plexmedia/ca"
      ];
      NetworkNamespacePath = "/run/netns/torrent";
      BindPaths = [ "/torrent/sockets" ];
      StateDirectoryMode = "751";
    };
    unitConfig.RequiresMountsFor = [ "/data/plexmedia/ca" ];
    after = [ "wireguard-${vpnCfg.name}.service" ];
  };
}
