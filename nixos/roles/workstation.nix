{ config, lib, pkgs, ... }:
let
  nixNetrcFile = pkgs.runCommand "nix-netrc-file" {
    hostname = "cache.lumi.guide";
    username = "lumi";
  } ''
    cat > $out <<EOI
    machine $hostname
    login $username
    password ${
      builtins.readFile
      /home/yorick/engineering/lumi/secrets/shared/passwords/nix-serve-password
    }
    EOI
  '';
in {
  imports = [ ./graphical.nix ];

  users.extraUsers.yorick.extraGroups = [ "input" "wireshark" "dialout" ];
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint pkgs.cups-dymo ];
  };
  environment.systemPackages = with pkgs; [
    pkgs.ghostscript
    pkgs.yubikey-manager
    pkgs.glib
  ];
  environment.sessionVariables.XDG_DATA_DIRS = with pkgs; [
    "${gnome-themes-extra}/share"
    "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
  ];
  programs.dconf.enable = true;
  virtualisation.virtualbox.host.enable = false;
  yorick.support32bit = true;
  services.pcscd.enable = true;
  #environment.systemPackages = [pkgs.yubikey-manager];
  fonts.fonts = [ pkgs.emojione ];
  programs.wireshark.enable = true;
  nix = {
    gc.automatic = pkgs.lib.mkOverride 30 false;
    settings.substituters = [
      "https://cache.nixos.org"
      "https://cache.lumi.guide/"
      #"s3://yori-nix?endpoint=s3.eu-central-003.backblazeb2.com&profile=backblaze-read"
      #"https://nixpkgs-wayland.cachix.org"
    ];
    settings.trusted-substituters = config.nix.settings.substituters ++ [
      "ssh://yorick@jupiter.serokell.io"
      "ssh-ng://jupiter"
      "https://serokell.cachix.org"
    ];
    settings.trusted-public-keys = [
      "serokell:ic/49yTkeFIk4EBX1CZ/Wlt5fQfV7yCifaJyoM+S3Ss="
      "serokell-1:aIojg2Vxgv7MkzPJoftOO/I8HKX622sT+c0fjnZBLj0="
      (lib.mkIf config.yorick.lumi-vpn.enable "cache.lumi.guide-1:z813xH+DDlh+wvloqEiihGvZqLXFmN7zmyF8wR47BHE=")
      "serokell.cachix.org-1:5DscEJD6c1dD1Mc/phTIbs13+iW22AVbx0HqiSb+Lq8="
      #"nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "yorick:Pmd0gyrTvVdzpQyb/raHJKdoOag8RLaj434qBgMm4I0="
    ];
    extraOptions = lib.mkIf config.yorick.lumi-vpn.enable ''
      netrc-file = ${nixNetrcFile}
    # '';
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
  };
  virtualisation.libvirtd.enable = true;
  users.users.yorick.extraGroups = [ "libvirtd" "pico" ];
  users.users.yorick.shell = pkgs.fish;
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="5bf0", MODE="0664", GROUP="dialout"
  '';

  # picoscope
  #users.users.yorick.extraGroups = ["pico"];
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/95-pico.rules" ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0ce9", MODE="664",GROUP="pico"
    '')
  ];
  users.groups.pico = { };

  # development
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_10;
  };

  # git
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 1024000000;

  yorick.lumi-vpn.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # todo: support32bit?
    pulse.enable = true;
    media-session.config.bluez-monitor.rules = [
      {
        # Matches all cards
        matches = [ { "device.name" = "~bluez_card.*"; } ];
        actions = {
          "update-props" = {
            "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
            # mSBC is not expected to work on all headset + adapter combinations.
            "bluez5.msbc-support" = true;
            # SBC-XQ is not expected to work on all headset + adapter combinations.
            "bluez5.sbc-xq-support" = true;
          };
        };
      }
      {
        matches = [
          # Matches all sources
          { "node.name" = "~bluez_input.*"; }
          # Matches all outputs
          { "node.name" = "~bluez_output.*"; }
        ];
        actions = {
          "node.pause-on-idle" = false;
        };
      }
    ];
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr xdg-desktop-portal-gtk ];
    gtkUsePortal = true;
  };
}
