{ inputs, lib, ... }:

{
  imports = [
    ../../roles/server.nix
    ../../roles/homeserver.nix
    "${inputs.mono}/image"
    "${inputs.mono}/configurations/gateway.nix"
    # read-only nixpkgs module: uses cfg.pkgs directly without appendOverlays,
    # so the crossOverlays below don't leak into pkgsBuildBuild.
    # TODO(26.11): test if this can be removed (tested on 26.05: still needed,
    # without it pkgsBuildBuild.systemd loses tpm2-tss)
    "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs/read-only.nix"
  ];
  nixpkgs.pkgs = import inputs.nixpkgs {
    localSystem.system = "x86_64-linux";
    crossSystem.system = "aarch64-linux";
    overlays = [
      inputs.self.overlays.default
      inputs.mono.overlays.default
      (import ../../roles/server-pkgs-overlay.nix)
      (_final: prev: {
        # TODO: upstream mono-gateway-kernel uses linuxManualConfig with a
        # static configfile and ignores structuredExtraConfig. Fix it there
        # so this can be done with a normal .override.
        mono-gateway-kernel = prev.mono-gateway-kernel.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./emc2305-skip-thermal-when-unbound.patch
          ];
          postConfigure = (old.postConfigure or "") + ''
            rm $buildRoot/.config
            cp ${old.passthru.configfile} $buildRoot/.config
            chmod +w $buildRoot/.config
            cat >> $buildRoot/.config <<'EOF'
            CONFIG_CPU_IDLE=y
            CONFIG_CPU_IDLE_GOV_MENU=y
            CONFIG_CPU_IDLE_GOV_TEO=y
            CONFIG_ARM_PSCI_CPUIDLE=y
            EOF
            make "''${makeFlags[@]}" olddefconfig
          '';
        });
      })
    ];
    crossOverlays = [
      (_final: prev: {
        systemd = prev.systemd.override {
          withTpm2Tss = false;
        };
        libnfnetlink = prev.mono-gateway-libnfnetlink;
        libnetfilter_conntrack = prev.mono-gateway-libnetfilter_conntrack;
      })
    ];
    config.allowUnfree = true;
  };
  # 26.05 defaults to systemd stage-1, but mono's hardware.nix still uses
  # scripted initrd hooks (extraUtilsCommands/postMountCommands)
  boot.initrd.systemd.enable = false;
  services.strongswan-swanctl.enable = lib.mkForce false;
  networking.hostName = lib.mkForce "zazu";
  services.vmagent.checkConfig = false; # todo: use buildPackages
  hardware.enableRedistributableFirmware = lib.mkForce false;
  # stop disk writes
  boot.tmp.useTmpfs = true;
  systemd.network.networks."eth0" = {
    name = "eth0";
    DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };
  systemd.services.status-led = {
    description = "Set status LED to white";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo 0 > /sys/class/leds/status:blue/brightness
      echo 0 > /sys/class/leds/status:green/brightness
      echo 0 > /sys/class/leds/status:red/brightness
      echo 1 > /sys/class/leds/status:white/brightness
    '';
  };
  services.sshguard.enable = lib.mkForce false; # broken
}
