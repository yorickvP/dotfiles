self: super:
let
  overrideOlder = original: override: let
    lib = super.lib;
    newpkgver = lib.getVersion (override original);
    oldpkgver = lib.getVersion original;
    in if (lib.versionOlder oldpkgver newpkgver) then original.overrideDerivation override else original;
in
{
  # spotify = overrideOlder pkgs.spotify (attrs: rec {
      # version = "1.0.48.103.g15edf1ec-94";
      # name = "spotify-${version}";
      # src = fetchurl {
      #   url = "http://repository-origin.spotify.com/pool/non-free/s/spotify-client/spotify-client_${version}_amd64.deb";
      #   sha256 = "0rpwxgxv2ihfhlri98k4n87ynlcp569gm9q6hd8jg0vd2jgji8b3";
      # };
  #});

}
