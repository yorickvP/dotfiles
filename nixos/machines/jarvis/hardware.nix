{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.dell-xps-13-9360
  ];

  boot.kernelModules = [ "i8k" ];
  boot.extraModprobeConfig = ''
    options i8k ignore_dmi=1
  '';
  fileSystems."/".options = [
    "defaults"
    "relatime"
    "discard"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."nix-crypt".allowDiscards = true;

  services.undervolt = rec {
    enable = true;
    coreOffset = -50;
    gpuOffset = -50;
    uncoreOffset = -50;
    analogioOffset = -50;
  };
  services.tlp.settings = {
    "CPU_SCALING_GOVERNOR_ON_AC" = "performance";
    "CPU_SCALING_GOVERNOR_ON_BAT" = "powersave";
  };

  networking.wireless.iwd.enable = true;
  systemd.network = {
    wait-online.anyInterface = true;
    networks."10-wlan" = {
      matchConfig.Type = "wlan";
      DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };
    # DHCP on any USB ethernet
    networks."80-usb-ethernet" = {
      matchConfig = {
        Property = "ID_BUS=usb";
        Type = "ether";
      };
      DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };
  };

  hardware.bluetooth.enable = true;

  hardware.firmware = [ pkgs.wireless-regdb ];
}
