{
  inputs,
  lib,
  ...
}:
let
  mkMicrovm =
    {
      name,
      tapId,
      mac,
      ip,
      varSize ? 256,
      zvol ? "/dev/zvol/dpool/${name}",
      guestConfig ? { },
    }:
    {
      autostart = false;
      config =
        { pkgs, ... }:
        {
          imports = [
            ../../roles/base.nix
            guestConfig
          ];
          microvm = {
            binScripts.tap-up = lib.mkAfter ''
              ${lib.getExe' pkgs.iproute2 "ip"} link set dev ${tapId} master microbridge
            '';
            vcpu = 16;
            mem = 8192;
            hotpluggedMem = 8192;
            hotplugMem = 32768;
            hypervisor = "cloud-hypervisor";
            optimize.enable = true;
            writableStoreOverlay = "/nix/.rw-store";
            interfaces = [
              {
                type = "tap";
                id = tapId;
                inherit mac;
              }
            ];
            volumes = [
              {
                mountPoint = "/var";
                image = "var.img";
                size = varSize;
              }
              {
                mountPoint = "/home";
                image = zvol;
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
                source = "/var/lib/microvms/${name}/ssh-host-keys";
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
          networking.useNetworkd = true;
          networking.tempAddresses = "disabled";
          systemd.network.enable = true;
          systemd.network.networks."10-e" = {
            matchConfig.Name = "e*";
            addresses = [ { Address = "${ip}/24"; } ];
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

          security.sudo-rs = {
            enable = true;
            wheelNeedsPassword = false;
          };

          users.users.root.password = "";
          users.users.yorick.password = "";
        };
    };
in
{
  imports = [
    inputs.microvm.nixosModules.host
  ];
  systemd.network = {
    netdevs."20-microbridge".netdevConfig = {
      Kind = "bridge";
      Name = "microbridge";
    };
    networks."20-microbridge" = {
      matchConfig.Name = "microbridge";
      addresses = [ { Address = "192.168.81.1/24"; } ];
      networkConfig.ConfigureWithoutCarrier = true;
      linkConfig.RequiredForOnline = "no";
    };

  };
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "microbridge" ];
  };
  networking.extraHosts = ''
    192.168.81.2 microvm
  '';

  microvm.vms.microvm = mkMicrovm {
    name = "microvm";
    tapId = "vm-a1";
    mac = "02:00:00:00:00:01";
    ip = "192.168.81.2";
    guestConfig =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
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
        ];
      };
  };

}
