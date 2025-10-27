{ lib, buildGoModule }:

buildGoModule rec {
  pname = "y-connect-idle";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-bj7NnknlKwXM0pHErt6JvHoZ8JCvRkvGFQFHsVesbEk=";

  meta = with lib; {
    description = "Export logind idle hint to home-assistant";
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
