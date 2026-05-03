{ pkgs, ... }:
{
  imports = [
    ../../services/backup.nix
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/borgbackup 0755 root root -"
  ];

  systemd.services.borgbackup-snapshot = {
    description = "Create and mount ZFS snapshot for borgbackup";
    path = [
      pkgs.zfs
      pkgs.util-linux
    ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/borgbackup" ];
      BindsTo = [ "borgbackup-job-backup.service" ];
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      zfs destroy ssdpool/root/var@borgbackup || true
      zfs snapshot ssdpool/root/var@borgbackup
      mountpoint -q /mnt/borgbackup || mount -t zfs ssdpool/root/var@borgbackup /mnt/borgbackup
    '';
    preStop = ''
      umount /mnt/borgbackup || true
      zfs destroy ssdpool/root/var@borgbackup || true
    '';
  };

  systemd.services.borgbackup-job-backup = {
    requires = [ "borgbackup-snapshot.service" ];
    after = [ "borgbackup-snapshot.service" ];
  };

  services.borgbackup.jobs.backup = {
    paths = [
      "/mnt/borgbackup/lib/hass"
      "/mnt/borgbackup/lib/paperless"
      "/mnt/borgbackup/lib/redis-paperless"
      "/mnt/borgbackup/lib/zigbee2mqtt"
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
