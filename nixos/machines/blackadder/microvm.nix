{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.microvm.nixosModules.host
  ];
  networking.bridges.microbridge.interfaces = [ ];
  networking.interfaces.microbridge = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.81.1";
        prefixLength = 24;
      }
    ];
  };
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "microbridge" ];
  };
  networking.extraHosts = "192.168.81.2 microvm";
  # networking.interfaces.vm-a1 = {
  #   virtual = true;
  #   virtualType = "tap";
  # };
  microvm.vms.microvm = {
    autostart = false;
    config = (
      { config, pkgs, ... }:
      {
        microvm = {
          binScripts.tap-up = lib.mkAfter ''
            ${lib.getExe' pkgs.iproute2 "ip"} link set dev vm-a1 master microbridge
          '';
          vcpu = 16;
          mem = 8192;
          hotpluggedMem = 8192;
          hotplugMem = 65536;
          hypervisor = "cloud-hypervisor";
          optimize.enable = true;
          writableStoreOverlay = "/nix/.rw-store";
          vsock.cid = 4;
          interfaces = [
            {
              type = "tap";
              id = "vm-a1";
              mac = "02:00:00:00:00:01";
            }
          ];
          volumes = [
            {
              mountPoint = "/var";
              image = "var.img";
              size = 256;
            }
            {
              mountPoint = "/home";
              image = "/dev/zvol/dpool/microvm";
              autoCreate = false;
            }
          ];
          shares = [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
            {
              proto = "virtiofs";
              tag = "ssh-keys";
              source = "/var/lib/microvms/microvm/ssh-host-keys";
              mountPoint = "/etc/ssh/host-keys";
            }
          ];
        };
        services.openssh.hostKeys = [
          {
            path = "/etc/ssh/host-keys/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
        services.resolved.enable = true;
        networking.useDHCP = false;
        networking.useNetworkd = true;
        networking.tempAddresses = "disabled";
        systemd.network.enable = true;
        systemd.network.networks."10-e" = {
          matchConfig.Name = "e*";
          addresses = [ { Address = "192.168.81.2/24"; } ];
          routes = [ { Gateway = "192.168.81.1"; } ];
        };
        networking.firewall.enable = false;
        systemd.settings.Manager.DefaultTimeoutStopSec = "5s";
        systemd.mounts = [
          {
            what = "store";
            where = "/nix/store";
            overrideStrategy = "asDropin";
            unitConfig.DefaultDependencies = false;
          }
        ];
        networking.nameservers = [ "192.168.2.254" ];
        programs.fish.enable = true;
        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            zlib
            libusb1
            libxcrypt-legacy
          ];
        };
        system.stateVersion = "25.11";

        nix.package = pkgs.lixPackageSets.latest.lix;
        security.sudo = {
          enable = true;
          wheelNeedsPassword = false;
        };

        networking.domain = "yori.cc";
        time.timeZone = "Europe/Amsterdam";
        users.mutableUsers = false;
        users.users.root = {
          openssh.authorizedKeys.keys = config.users.users.yorick.openssh.authorizedKeys.keys;
          password = "";

        };
        services.timesyncd.enable = true;
        users.users.yorick = {
          isNormalUser = true;
          uid = 1000;
          extraGroups = [ "wheel" ];
          group = "users";
          openssh.authorizedKeys.keys = with (import ../../sshkeys.nix); yorick;
          password = "";
          createHome = true;
        };

        # Nix
        # nixpkgs.config.allowUnfree = true;

        #nix.buildCores = config.nix.maxJobs;
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

            #vim

            # system stuff
            ethtool
            inetutils
            # iotop
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

            #gitMinimal

            cargo
            expect
            fd
            fx
            fzf
            gcc
            ghostty.terminfo
            git
            gnumake
            google-cloud-sdk
            htop
            imagemagick
            jless
            jo
            jq
            kubectl
            libarchive
            llm-agents.ccusage
            llm-agents.claude-code
            lnav
            magic-wormhole
            mitmproxy
            moreutils
            mosh
            nodejs
            openssl
            pkg-config
            pv
            python3
            ripgrep
            screen
            spacer
            sqlite-interactive
            sshfs-fuse
            stern
            tmux
            trurl
            unzip
            uv
            yq
            zip
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
    );
  };

}
