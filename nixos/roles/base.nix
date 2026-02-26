{
  config,
  pkgs,
  lib,
  ...
}:
{
  nix.package = pkgs.lixPackageSets.latest.lix;

  networking.domain = "yori.cc";
  time.timeZone = "Europe/Amsterdam";
  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = config.users.users.yorick.openssh.authorizedKeys.keys;
  };
  services.timesyncd.enable = true;
  users.users.yorick = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    group = "users";
    openssh.authorizedKeys.keys = with (import ../sshkeys.nix); yorick;
    createHome = true;
  };

  # Nix
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    extra-deprecated-features = url-literals
  '';

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    # todo: overridden from forgejo
    settings.AcceptEnv = lib.mkForce "GIT_PROTOCOL COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION";
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
      attic-client
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

  nix.settings.trusted-users = [ "@wheel" ];

  # enabled by fish, slow
  documentation.man.generateCaches = false;
}
