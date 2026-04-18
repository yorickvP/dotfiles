{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [
    "nct6775"
    "i2c-dev"
    "i2c-piix4"
  ];
  networking.hostId = "c7736638";

  systemd.network.networks."10-wan" = {
    name = "enp9s0";
    DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };
  environment.systemPackages = [
    pkgs.openrgb
  ];
  services.xserver.videoDrivers = [
    "modesetting"
  ];
  hardware.cpu.amd = {
    ryzen-smu.enable = true;
    updateMicrocode = true;
  };

  # prevent desk usb hub from suspending
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2109", ATTR{idProduct}=="2811", TEST=="power/control", ATTR{power/control}="on"
  '';
}
