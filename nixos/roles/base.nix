{
  pkgs,
  lib,
  ...
}:
let
  sshkeys = import ../sshkeys.nix;
in
{
  networking = {
    domain = "yori.cc";
    useDHCP = false;
  };

  systemd.network.enable = true;
  time.timeZone = "Europe/Amsterdam";

  # CVE-2026-31431 (copy.fail): block AF_ALG autoload of algif_aead
  boot.blacklistedKernelModules = [ "algif_aead" ];
  boot.extraModprobeConfig = ''
    install algif_aead /bin/false
  '';

  users = {
    mutableUsers = false;
    users.root = {
      openssh.authorizedKeys.keys = sshkeys.yorick-root;
    };
    users.yorick = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" ];
      group = "users";
      openssh.authorizedKeys.keys = sshkeys.yorick;
      createHome = true;
    };
  };

  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };

  nix = {
    package = pkgs.lixPackageSets.latest.lix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "@wheel" ];
    };
  };

  services = {
    openssh = {
      enable = true;
      authorizedKeysInHomedir = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        # todo: overridden from forgejo
        AcceptEnv = lib.mkForce "GIT_PROTOCOL COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION";
      };
    };
    timesyncd.enable = true;
  };

  environment.systemPackages =
    with pkgs;
    [
      rlwrap

      # system stuff
      ethtool
      inetutils
      powertop
      htop
      psmisc
      lsof
      ncdu
      btop

      # utils
      file
      which
      reptyr
      tmux
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
      arp-scan
    ]
    ++ (
      with pkgs.pkgsBuildBuild;
      (map (x: x.terminfo) [
        alacritty
        st
        foot
        ghostty
        tmux
      ])
    );

  # enabled by fish, slow
  documentation.man.generateCaches = false;

  hardware.enableRedistributableFirmware = true;
}
