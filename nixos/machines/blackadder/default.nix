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

    mickey = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshkeys.mickey ++ sshkeys.bram;
      packages = with pkgs; [
        git cmake gnumake gcc python3 python3.pkgs.pip screen vim
      ];
      extraGroups = [ "docker" ];
    };
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
    enableNvidia = true;
    storageDriver = "overlay2";
  };
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
  services.fooocus = {
    enable = true;
    listen = "0.0.0.0";
  };
  networking.firewall.allowedTCPPorts = [ config.services.fooocus.port ];
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "550.54.14";
    sha256_64bit = "sha256-jEl/8c/HwxD7h1FJvDD6pP0m0iN7LLps0uiweAFXz+M=";
    sha256_aarch64 = "sha256-sProBhYziFwk9rDAR2SbRiSaO7RMrf+/ZYryj4BkLB0=";
    openSha256 = "sha256-F+9MWtpIQTF18F2CftCJxQ6WwpA8BVmRGEq3FhHLuYw=";
    settingsSha256 = "sha256-m2rNASJp0i0Ez2OuqL+JpgEF0Yd8sYVCyrOoo/ln2a4=";
    persistencedSha256 = "sha256-XaPN8jVTjdag9frLPgBtqvO/goB5zxeGzaTU0CdL6C4=";
    #patches = config.boot.kernelPackages.nvidiaPackages.latest.patches;
  };
}
