{ config, lib, pkgs, ... }:
{
  imports = [
    <yori-nix/roles/graphical.nix>
  ];
  users.extraUsers.yorick.extraGroups = ["input"];
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
  };
  environment.systemPackages = [pkgs.ghostscript pkgs.yubikey-manager];
  #services.xserver.displayManager.sessionCommands = ''
  #  gpg-connect-agent /bye
  #  unset SSH_AGENT_PID
  #  export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
  #'';
  virtualisation.virtualbox.host.enable = true;
  yorick.support32bit = true;
  # yubikey
  hardware.u2f.enable = true;
  services.pcscd.enable = true;
  #environment.systemPackages = [pkgs.yubikey-manager];
  nix = {
    gc.automatic = pkgs.lib.mkOverride 30 false;
    binaryCaches = [
      "https://cache.nixos.org"
    ];
    trustedBinaryCaches = config.nix.binaryCaches ++ [
      "ssh://yorick@jupiter.serokell.io"
      "ssh-ng://jupiter"
      "https://cache.lumi.guide"
      "https://serokell.cachix.org"
    ];
    binaryCachePublicKeys = [
      "serokell:ic/49yTkeFIk4EBX1CZ/Wlt5fQfV7yCifaJyoM+S3Ss="
      "serokell-1:aIojg2Vxgv7MkzPJoftOO/I8HKX622sT+c0fjnZBLj0="
      "cache.lumi.guide-1:z813xH+DDlh+wvloqEiihGvZqLXFmN7zmyF8wR47BHE="
      "serokell.cachix.org-1:5DscEJD6c1dD1Mc/phTIbs13+iW22AVbx0HqiSb+Lq8="
      "disciplina.cachix.org-1:zDeIFV5cu22v04EUuRITz/rYxpBCGKY82x0mIyEYjxE="
    ];
    extraOptions = ''
     netrc-file = ${nixnetrc}
    '';
  };
}
