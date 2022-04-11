{ config, lib, pkgs, ... }:
let
  cfg = config.yorick.lumi-cache;
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
  options.yorick.lumi-cache = with lib; {
    enable = mkEnableOption "lumi cache";
  };
  config = lib.mkIf cfg.enable {
    nix = {
      settings.substituters = [ "https://cache.lumi.guide/" ];
      settings.netrc-file = nixNetrcFile;
      settings.trusted-public-keys = [
        "cache.lumi.guide-1:z813xH+DDlh+wvloqEiihGvZqLXFmN7zmyF8wR47BHE="
      ];
    };
  };
}
