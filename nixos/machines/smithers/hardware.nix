{
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
  ];

  services.thermald.enable = true;
  services.thermald.ignoreCpuidCheck = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "54a8968e";

  services.fprintd.enable = true;
  hardware.intelgpu = {
    driver = "i915";
    vaapiDriver = "intel-media-driver";
    computeRuntime = "legacy";
  };

  boot = {
    # flickerfree
    initrd.systemd.enable = true;
    initrd.verbose = false;
    plymouth.enable = true;
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "i915.enable_guc=3"
    ];
  };
  boot.loader.timeout = 0;

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = true;
      Network.NameResolvingService = "resolvconf";
      Network.RoutePriorityOffset = 2000;
    };
  };
  # DHCP on any USB ethernet
  systemd.network.networks."80-usb-ethernet" = {
    matchConfig = {
      Property = "ID_BUS=usb";
      Type = "ether";
    };
    DHCP = "yes";
    linkConfig.RequiredForOnline = "no";
  };
  zramSwap = {
    enable = true;
    memoryPercent = 30;
  };
}
