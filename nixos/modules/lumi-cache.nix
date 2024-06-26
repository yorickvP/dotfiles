{ config, lib, pkgs, ... }:
let
  cfg = config.yorick.lumi-cache;
in {
  options.yorick.lumi-cache = with lib; {
    enable = mkEnableOption "lumi cache";
  };
  config = lib.mkIf cfg.enable {
    age.secrets.nix-netrc.file = ../../secrets/nix-netrc.age;
    nix.settings = {
      substituters = [ "https://cache.lumi.guide/?priority=50" ];
      netrc-file = lib.mkForce config.age.secrets.nix-netrc.path;
      trusted-public-keys = [
        "cache.lumi.guide-1:z813xH+DDlh+wvloqEiihGvZqLXFmN7zmyF8wR47BHE="
      ];
    };
  };
}
