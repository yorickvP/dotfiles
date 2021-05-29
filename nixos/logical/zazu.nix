# Edit this configuration file to define what should be installed on your system.  Help is available in the configuration.nix(5) man page and in the NixOS manual (accessible by running ‘nixos-help’).
let sources = import ../../nix/sources.nix; in
{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../physical/apu2c4.nix
      #<yori-nix/roles/homeserver.nix>
      ../roles
      "${sources.nixos-hardware}/pcengines/apu"
      <nixpkgs/nixos/modules/profiles/minimal.nix>
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.enp1s0.accept_ra" = 2;
  };
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp1s0 = {
    useDHCP = true;
    tempAddress = "disabled";
  };
  #networking.interfaces.enp2s0.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = false;
  networking.interfaces.enp2s0 = {
    tempAddress = "disabled";
    ipv4.addresses = [{
      address = "192.168.178.1";
      prefixLength = 24;
    }];
    useDHCP = true;
  };
  # systemd.services.network-link-br0.unitConfig.After = lib.mkForce [ "network-pre.target" "br0-netdev.service" ];
  # systemd.services.network-link-br0.unitConfig.BindsTo = lib.mkForce [ "br0-netdev.service" ];
  networking.nat = {
    enable = true;
    externalInterface = "dslite1";
    internalIPs = [ "192.168.178.1/24" ];
  };
  networking.defaultGateway = {
    address = "192.0.0.1";
    interface = "dslite1";
  };
  systemd.services.dslite1-netdev = {
    wantedBy = [ "network-setup.service" "sys-subsystem-net-devices-dslite1.device" ];
    bindsTo = [];
    partOf = [ "network-setup.service" ];
    after = [ "network-pre.target" "network-addresses-enp1s0.service" "network-link-enp1s0.service" ];
    before = [ "network-setup.service" ];
    path = [ pkgs.iproute ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip tunnel add dslite1 mode ip4ip6 local 2a02:a212:2200:4c00:20d:b9ff:fe56:ba04 remote 2001:730:2000:2::31 encaplimit none
      ip link set dslite1 up
    '';
    postStop = ''
      ip link del dslite1 || true
    '';
  };
  networking.interfaces.dslite1 = {
    mtu = 1452; # todo: ipv6 fragmenting?
    ipv4.addresses = [{
      address = "192.0.0.2";
      prefixLength = 24;
    }];
  };
  # networking.bridges = {
  #   br0.interfaces = [ "enp2s0" "enp3s0" ];
  # };
  networking.dhcpcd.persistent = true;
  # request prefix delegation
  networking.dhcpcd.extraConfig = ''
    noipv6rs
    ipv6only
    interface enp1s0
    ipv6rs
    iaid 1
    ia_pd 1/::/60 enp2s0/0/64
  '';
  services.dnsmasq = {
    enable = true;
    servers = [ "8.8.8.8" "1.1.1.1" ];
  };
  services.dhcpd4 = {
    interfaces = [ "enp2s0" ];
    enable = true;
    machines = [
      { hostName = "amateria";    ethernetAddress = "a8:a1:59:15:8b:63"; ipAddress = "192.168.178.42"; }
      { hostName = "blackadder";  ethernetAddress = "a8:a1:59:03:8a:75"; ipAddress = "192.168.178.33"; }
      { hostName = "frumar";      ethernetAddress = "bc:5f:f4:e8:42:9f"; ipAddress = "192.168.178.37"; }
      { hostName = "jarvis";      ethernetAddress = "18:1d:ea:35:13:58"; ipAddress = "192.168.178.34"; }
      { hostName = "jarvis-dock"; ethernetAddress = "64:4b:f0:10:05:f2"; ipAddress = "192.168.178.13"; }
      { hostName = "printer";     ethernetAddress = "30:05:5c:44:20:a7"; ipAddress = "192.168.178.26"; }
      { hostName = "raspberrypi"; ethernetAddress = "b8:27:eb:b9:ec:3a"; ipAddress = "192.168.178.21"; }
      { hostName = "smartMeter";  ethernetAddress = "5c:cf:7f:26:ca:91"; ipAddress = "192.168.178.30"; }
      { hostName = "gang-ap";     ethernetAddress = "b4:fb:e4:2d:fc:f3"; ipAddress = "192.168.178.32"; }
      { hostName = "woodhouse";   ethernetAddress = "94:c6:91:15:1f:c5"; ipAddress = "192.168.178.39"; }
    ];
    extraConfig = ''
      subnet 192.168.178.0 netmask 255.255.255.0 {
        option subnet-mask 255.255.255.0;
        option broadcast-address 192.168.178.255;
        option routers 192.168.178.1;
        option domain-name-servers 192.168.178.1;
        range 192.168.178.3 192.168.178.200;
      }
    '';
  };
  services.radvd = {
    enable = true;
    config = ''
      interface enp2s0 {
        AdvSendAdvert on;
        prefix 2a02:a212:2200:4c70::/64 {
          AdvOnLink on;
          AdvAutonomous on;
        };
      };
    '';
  };
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  services.fstrim.enable = true;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   wget vim
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
  services.udisks2.enable = false;
  boot.supportedFilesystems = lib.mkForce [ "ext4" ];
  boot.initrd.supportedFilesystems = lib.mkForce [ "ext4" ];
  security.polkit.enable = false;
  nixpkgs.overlays = [ (self: super: {
    dhcpcd = super.dhcpcd.overrideAttrs (o: rec {
      pname = "dhcpcd";
      version = "8.1.9";
      src = self.fetchurl {
        url = "mirror://roy/${pname}/${pname}-${version}.tar.xz";
        sha256 = "1kzv61bgrd0zwiy6r218zkccx36j9p5mz1gxqvbhg05xn9g50alf";
      };
      patches = [];
    });
  }) ];
}
