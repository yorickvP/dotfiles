self: super:
let
  overrideOlder = original: override: with self.lib; let
  newpkgver = getVersion (override original);
  oldpkgver = getVersion original;
    in if (versionOlder oldpkgver newpkgver) then original.overrideDerivation override else original;
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

  haskellPackages = with super.haskell.lib; super.haskellPackages.extend (hself: hsuper:{
    X11 = overrideCabal hsuper.X11 (drv: {
      librarySystemDepends = drv.librarySystemDepends ++ [ self.xorg.libXScrnSaver ];
    });
  });
}
