let secrets = import ../secrets.nix;
in { config, pkgs, lib, name, ... }:
let
  machine = name;
  vpn = import ../vpn.nix;
in {
  imports = [
    ../modules/tor-hidden-service.nix
    ../modules/nginx.nix
    ../modules/lumi-cache.nix
    ../modules/lumi-vpn.nix
    ../deploy/keys.nix
    ../services
  ];

  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

  networking.domain = "yori.cc";
  networking.hostName = machine;
  time.timeZone = "Europe/Amsterdam";
  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys =
      config.users.users.yorick.openssh.authorizedKeys.keys;
    # root password is useful from console, ssh has password logins disabled
    hashedPassword = secrets.pennyworth_hashedPassword; # TODO: generate own

  };
  services.timesyncd.enable = true;
  users.users.yorick = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    group = "users";
    openssh.authorizedKeys.keys = with (import ../sshkeys.nix); yorick;
    hashedPassword = secrets.yorick_hashedPassword;
    createHome = true;
  };

  # Nix
  nixpkgs.config.allowUnfree = true;

  #nix.buildCores = config.nix.maxJobs;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Networking
  networking.enableIPv6 = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    # v important.
    cowsay # ponysay
    ed # ed, man!
    sl
    rlwrap

    #vim

    # system stuff
    ethtool
    inetutils
    pciutils
    usbutils
    # iotop
    powertop
    htop
    psmisc
    lsof
    smartmontools
    hdparm
    lm_sensors
    ncdu

    # utils
    file
    which
    reptyr
    tmux
    bc
    mkpasswd
    shadow

    # archiving
    xdelta
    libarchive
    atool

    # network
    nmap
    mtr
    bind
    socat
    libressl.nc
    lftp
    wget
    rsync

    #gitMinimal
  ];
  nix.gc.automatic = true;

  services.avahi = {
    ipv6 = true;
    hostName = machine;
  };
  deployment.keyys = [ (../keys + "/wg.${machine}.key") ];
  networking.wireguard.interfaces.wg-y = {
    privateKeyFile = "/root/keys/wg.${machine}.key";
    ips = [ vpn.ips.${machine} ];
    listenPort = 31790;
    peers = [{
      publicKey = vpn.keys.pennyworth;
      endpoint = "pennyworth.yori.cc:31790";
      allowedIPs = [ "10.209.0.0/24" ];
      persistentKeepalive = 30;
    }];
    postSetup = "ip link set dev wg-y mtu 1371";
  };
  security.acme.defaults.email = "acme@yori.cc";
  security.acme.acceptTerms = true;
  nix.settings.trusted-public-keys =
    [ "yorick:Pmd0gyrTvVdzpQyb/raHJKdoOag8RLaj434qBgMm4I0=" ];

  nix.settings.trusted-users = [ "@wheel" ];
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    disabledCollectors = [ "rapl" ];
  };
  networking.firewall.interfaces.wg-y.allowedTCPPorts = [ 9100 ];
  xdg.autostart.enable = false;
}
