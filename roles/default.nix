let secrets = import <secrets>;
in
{ config, pkgs, lib, ...}:
let
  machine = lib.removeSuffix ".nix" (builtins.baseNameOf <nixos-config>);
in
{
	imports = [
    ../modules/tor-hidden-service.nix
    ../modules/nginx.nix
    <yori-nix/deploy/keys.nix>
    <yori-nix/services>
  ];
  networking.hostName = secrets.hostnames.${machine};
	time.timeZone = "Europe/Amsterdam";
	users.mutableUsers = false;
	users.extraUsers.root = {
		openssh.authorizedKeys.keys = config.users.extraUsers.yorick.openssh.authorizedKeys.keys;
    # root password is useful from console, ssh has password logins disabled
    hashedPassword = secrets.pennyworth_hashedPassword; # TODO: generate own

	};
  services.timesyncd.enable = true;
	users.extraUsers.yorick = {
	  isNormalUser = true;
	  uid = 1000;
	  extraGroups = ["wheel"];
	  group = "users";
	  openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [yorick];
	};

  # Nix
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = import ../packages;

  nix.buildCores = config.nix.maxJobs;

  # Networking
  networking.enableIPv6 = true;

  services.openssh = {
    enable = true;
  	passwordAuthentication = false;
  	challengeResponseAuthentication = false;
  };


  environment.systemPackages = with pkgs; [
    # v important.
    cowsay ponysay
    ed # ed, man!
    sl
    rlwrap

    vim

    # system stuff
    ethtool inetutils
    pciutils usbutils
    iotop powertop htop
    psmisc lsof
    smartmontools hdparm
    lm_sensors
    ncdu
    
    # utils
    file which
    reptyr
    tmux
    bc
    mkpasswd
    shadow
    
    # archiving
    xdelta
    atool
    unrar p7zip
    unzip zip

    # network
    nmap mtr bind
    socat netcat-openbsd
    lftp wget rsync

    git
    rxvt_unicode.terminfo
  ];
  nix.gc.automatic = true;

}

