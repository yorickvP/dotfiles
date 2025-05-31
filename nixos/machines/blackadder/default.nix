let
  sshkeys = import ../../sshkeys.nix;
in
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./3950x.nix
    ../../roles/workstation.nix
  ];

  system.stateVersion = "19.09";

  # backups
  services.znapzend = {
    enable = true;
    zetup = {
      "rpool/home-enc" = {
        plan = "1d=>1h,1m=>1w";
        destinations.frumar = {
          host = "root@frumar.home.yori.cc";
          dataset = "frumar-new/backup/blackadder";
          plan = "1w=>1d,1y=>1w,10y=>1m,50y=>1y";
        };
      };
      "rpool/home-enc/judith" = {
        plan = "1d=>1h,1m=>1w";
        destinations.frumar = {
          host = "root@frumar.home.yori.cc";
          dataset = "frumar-new/backup/blackadder/judith";
          plan = "1m=>1w";
        };
      };
    };
  };

  users.users = {
    judith = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshkeys.judith;
      packages = with pkgs; [ r8-cog ];
      # packages = with pkgs; [
      #   git cmake gnumake gcc python3 python3.pkgs.pip screen vim
      # ];
      extraGroups = [ "docker" ];
    };
  };

  # docker
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
  };
  virtualisation.oci-containers.backend = "docker";
  hardware.nvidia-container-toolkit.enable = true;
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
  # fooocus
  services.fooocus = {
    enable = true;
    listen = "0.0.0.0";
  };
  networking.firewall.allowedTCPPorts = [ config.services.fooocus.port ];
  yorick.dk-vpn = {
    enable = true;
    ip = "10.100.0.4";
  };
  services.postgresql = {
    enable = lib.mkForce true;
    ensureDatabases = [ "vierkantle" ];
    ensureUsers = [
      {
        name = "vierkantle";
        ensureDBOwnership = true;
      }
    ];
  };
  age.secrets."wg.dk.archbox.conf" = {
    file = ../../../secrets/wg.dk.archbox.conf.age;
  };
  # allow gpg agent forwarding
  services.openssh.settings.StreamLocalBindUnlink = true;
  services.journald.upload.enable = true;
  virtualisation.waydroid.enable = true;
}
