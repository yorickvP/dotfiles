{ config, pkgs, ... }:
{
  age.secrets.renovate-token.file = ../../secrets/renovate-token.age;

  nix.settings.allowed-users = [ "renovate" ];

  services.renovate = {
    enable = true;
    schedule = "daily";
    credentials = {
      RENOVATE_TOKEN = config.age.secrets.renovate-token.path;
    };
    runtimePackages = with pkgs; [
      nix
    ];
    settings = {
      platform = "forgejo";
      endpoint = "https://git.yori.cc/";
      gitAuthor = "Renovate <renovate@yori.cc>";
      autodiscover = true;
    };
  };
}
