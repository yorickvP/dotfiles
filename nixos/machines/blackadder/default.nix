let
  sshkeys = import ../../sshkeys.nix;
in
{ config, pkgs, lib, ... }: {
  imports = [ ./3950x.nix ../../roles/workstation.nix ];

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
  users.users = {
    lars = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshkeys.lars;
    };

    judith = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshkeys.judith;
      packages = with pkgs; [ r8-cog ];
      # packages = with pkgs; [
      #   git cmake gnumake gcc python3 python3.pkgs.pip screen vim
      # ];
    };
  };

  # docker
  virtualisation.docker.enable = true;
  users.users.yorick.extraGroups = [ "docker" ];

  nix.optimise.automatic = true;

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
