{ lib, buildGoModule }:

buildGoModule rec {
  pname = "notify-codes";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-WUTGAYigUjuZLHO1YpVhFSWpvULDZfGMfOXZQqVYAfs=";

  meta = with lib; {
    description = "Monitor KDE Connect notifications for authentication codes and copy them to clipboard";
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
