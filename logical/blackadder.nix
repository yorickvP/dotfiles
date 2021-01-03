{ config, pkgs, lib, ... }:
{
  imports =
    [ ../physical/3950x.nix
      ../roles/workstation.nix
    ];

  system.stateVersion = "19.09";

  yorick.lumi-vpn = {
    name = "yorick-homepc";
    mtu = 1408;
  };

  services.znapzend = {
    enable = true;
    pure = true;
    features = {
      zfsGetType = true;
      sendRaw = true;
    };
    zetup = {
      "rpool/home-enc" = {
        plan = "1d=>1h,1m=>1w";
        destinations.frumar = {
          host = "root@192.168.178.37";
          dataset = "frumar-new/backup/blackadder";
          plan = "1w=>1d,1y=>1w,10y=>1m,50y=>1y";
        };
      };
    };
  };
}
