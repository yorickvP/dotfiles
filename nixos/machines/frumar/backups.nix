{
  imports = [
    ../../services/backup.nix
  ];

  services.borgbackup.jobs.backup = {
    preHook = ''
      /run/current-system/sw/bin/zfs destroy ssdpool/root/var@borgbackup || true
      /run/current-system/sw/bin/zfs snapshot ssdpool/root/var@borgbackup
      sleep 5s
      ls /var/.zfs/snapshot/borgbackup > /dev/null
    '';
    postCreate = ''
      /run/current-system/sw/bin/zfs destroy ssdpool/root/var@borgbackup
    '';
    paths = [
      "/var/.zfs/snapshot/borgbackup/lib/hass"
      "/var/.zfs/snapshot/borgbackup/lib/paperless"
      "/var/.zfs/snapshot/borgbackup/lib/redis-paperless"
      "/var/.zfs/snapshot/borgbackup/lib/zigbee2mqtt"
    ];
  };

  services.znapzend = {
    enable = true;
    zetup = {
      "frumar-new/userdata" = {
        plan = "1w=>6h,1m=>1w,1y=>1m,2y=>6m,50y=>1y";
      };
      "frumar-new/plexmedia" = {
        plan = "1w=>6h,1m=>1w,1y=>1m,2y=>6m,50y=>1y";
      };
      "ssdpool/root" = {
        plan = "2d=>1d";
      };
      "ssdpool/root/var" = {
        plan = "1w=>1d";
        destinations.frumar-new = {
          dataset = "frumar-new/backup/ssdpool-root-var";
          plan = "1w=>1d,1m=>1w,1y=>1m,10y=>6m,50y=>1y";
        };
      };
    };
  };
}
