{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./3950x-hardware-config.nix
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

  networking.useDHCP = false;
  networking.interfaces.enp9s0.useDHCP = true;
  # systemd.network.links."98-namepolicy" = {
  #   matchConfig.OriginalName = "*";
  #   linkConfig.NamePolicy = "mac kernel database onboard slot path";
  # };
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
