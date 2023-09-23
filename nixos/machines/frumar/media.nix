{ config, pkgs, lib, ... }: {
  users.users.torrent = {
    isSystemUser = true;
    createHome = false;
    group = "torrent";
    home = "/torrent";
  };
  users.groups.torrent = {};
  systemd.tmpfiles.rules = [
    "d /torrent 770 torrent torrent"
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
    openFirewall = true;
  };
  services.radarr = {
    enable = true;
    group = "plex";
    user = "plex";
    openFirewall = true;
  };
  users.users.plex.packages = with pkgs; [
    ffmpeg
  ];
  users.users.yorick.packages = with pkgs; [
    pyrosimple
    rtorrent
    yscripts.absorb
  ];
}
