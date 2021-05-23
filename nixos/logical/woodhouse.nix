{ config, pkgs, lib, ... }:
let
  #secrets = import <secrets>;
mkFuseMount = device: opts: {
    # todo:  "ServerAliveCountMax=3" "ServerAliveInterval=30"

    device = "${pkgs.sshfsFuse}/bin/sshfs#${device}";
    fsType = "fuse";
    options = ["noauto" "x-systemd.automount" "_netdev" "users" "idmap=user"
               "defaults" "allow_other" "transform_symlinks" "default_permissions"
               "uid=1000"
               "reconnect" "IdentityFile=/root/.ssh/id_sshfs"] ++ opts;
};
in
{
  imports = [
    ../physical/nuc.nix
    ../roles/graphical.nix
    #<yori-nix/roles/homeserver.nix>
  ];

  # nixpkgs.overlays = [ (import (builtins.fetchTarball https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz)) ];
  # system.stateVersion = "17.09";

  # fuse mounts
  system.fsPackages = [ pkgs.sshfsFuse ];

  # programs.sway = {
  #   enable = true;
  #   extraSessionCommands = ''
  #     export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib.makeLibraryPath (with pkgs; [ libxkbcommon libglvnd wayland ])}
  #   '';
  # };
  #fileSystems."/mnt/frumar" = mkFuseMount "yorick@${secrets.hostnames.frumar}:/data/yorick" [];
  hardware.bluetooth.enable = true;

  # kodi ports
  networking.firewall.allowedTCPPorts = [7 8080 8443 9090 9777];
  users.users.tv = {
    isNormalUser = true;
    uid = 1043;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$hD4ESAGS8O1d$yctx6spOPZ0nt/6cgYpsWZ86UoXw3ISRpf2gbdhbl8JgDz6Psjx6JCqJ9NsMi5BHnXlgRRK/z2SVrTjHEsqQR.";
    packages = with pkgs; [ plex-media-player ];
  };
  services.xserver.windowManager.i3.enable = true;
  networking.useNetworkd = true;
  networking.dhcpcd.enable = false;
  services.resolved.enable = true;
  #services.nscd.enable = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.useDHCP = false;
  #services.xserver.enable = lib.mkForce false;
  # services.unifi = {
  #   enable = true;
  #   unifiPackage = pkgs.unifiStable;
  # };
  # todo: debug:
  services.resolved.extraConfig = "MulticastDNS=true";
  systemd.network.networks."40-eno1".networkConfig.MulticastDNS="yes";
  services.fstrim.enable = true;
}
