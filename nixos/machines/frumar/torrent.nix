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
}
