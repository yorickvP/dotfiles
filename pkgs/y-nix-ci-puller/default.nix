{ lib, buildGoModule }:

buildGoModule rec {
  pname = "y-nix-ci-puller";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-Db09ftEG9DJgN6mb4LaA2cOGiOjQx36DzeDqzAik2Fs=";

  meta = with lib; {
    description = "Pull CI-built nix store paths via MQTT and create GC roots";
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
