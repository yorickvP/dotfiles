{ inputs, lib, ... }:

{
  imports = [
    ../../roles/server.nix
    ../../roles/homeserver.nix
    "${inputs.mono}/image"
    "${inputs.mono}/configurations/gateway.nix"
  ];
  nixpkgs.pkgs = lib.mkForce (
    import inputs.nixpkgs {
      localSystem.system = "x86_64-linux";
      crossSystem.system = "aarch64-linux";
      overlays = [
        inputs.self.overlays.default
        inputs.mono.overlays.default
        (_final: prev: {
          # TODO: upstream mono-gateway-kernel uses linuxManualConfig with a
          # static configfile and ignores structuredExtraConfig. Fix it there
          # so this can be done with a normal .override.
          mono-gateway-kernel = prev.mono-gateway-kernel.overrideAttrs (old: {
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
      config.allowUnfree = true;
    }
  );
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
}
