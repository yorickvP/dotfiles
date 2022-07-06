{ config, pkgs, lib, ... }: {
  imports = [ ../physical/3950x.nix ../roles/workstation.nix ];

  system.stateVersion = "19.09";

  yorick.lumi-vpn = {
    name = "yorick-homepc";
    mtu = 1408;
    ip = "10.109.0.18";
  };

  # backups
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
          host = "root@frumar.home.yori.cc";
          dataset = "frumar-new/backup/blackadder";
          plan = "1w=>1d,1y=>1w,10y=>1m,50y=>1y";
        };
      };
    };
  };

  # lars user
  nix.settings.trusted-users = [ "lars" ];
  users.users.lars = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbieYUtRGQ4nf4glQvrZDn72doP6W2uw2z9VqFq5sZLROXYa4jW8nwx4h+BiArGs+VPwn6lfsP19PX6yNIk74C/SkO26S1Zvbe7ffNusi6PH2BQIOWeAYKk+eZH+ZOeD8z07uDB7QffwRLwzSaPFg+zfRzsMFoXH/GE9qOQ4lnfk8czTZL7zbZf/yS7mDFztClXFciYsVwgRXNiFpfc+9mOkU0oBWtGo/WGUhB0Hds3a4ylyjjVAcC/l1H2bvc/Q3d6bbn23pUFl2V78Yg1B4b1MT34qbBV6whXAQd7KM9tND2ZhpF2XQ7Spi1QlOac0jup+sE+3bbvcjNqTI05DwJO/dX5F2gSAFkvSY4ZPqSX5ilE/hj4DQuhRgLmQdbVl5IFV9aLYqUvJcCqX9jRFMly4YTFXsFz18rGkxOYGZabcE1usBM2zRVDTtEP6Si5ii76Ocvp8aNFBB2Kf1whg8tziTv3kQEQ9fd2sRtE2J3xveJiwXjUBU2uikSOKe8JP47Tb6PYlv7Ty/6OI51aUQn++R72VNajdBJ1r1osp7leqTJ+sXuLlWLo/a7lDpDmgEI7dbxqmpjLcMce0JzqLKlP1Q2U/nkYy86xkjSTH1rNUI2JAbJx3iTcGy7bq12yfjNfcGAqY4GVXvisK1cpbF0RCjaFExwtmzorljHh6ZHjQ== openpgp:0x60F7D1FD"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvdQ963wjgWyFMp6djRTqVwZr3/PQ/V+Qm5JTcxRTdY lumi@channelwood"
    ];
  };

  # docker
  virtualisation.docker.enable = true;
  users.users.yorick.extraGroups = [ "docker" ];

  # headphone control
  systemd.services.mdrd = {
    serviceConfig = {
      Type = "dbus";
      ExecStart = "${pkgs.mdrd}/bin/mdrd";
      BusName = "org.mdr";
    };
    wantedBy = [ "graphical-session.target" ];
  };
  services.dbus.packages = [ pkgs.mdrd ];
}
