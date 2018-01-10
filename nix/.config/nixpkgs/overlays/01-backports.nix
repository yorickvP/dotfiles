self: super:
let
pkgold = super;
  overrideOlder = original: override: let
  lib = super.lib;
    newpkgver = lib.getVersion (override original);
    oldpkgver = lib.getVersion original;
    in if (lib.versionOlder oldpkgver newpkgver) then original.overrideDerivation override else original;
in
{
  i3lock-color = overrideOlder super.i3lock-color (attrs: rec {
    version = "2.9.1-2017-09-10";
    name = "i3lock-color-${version}";
    src = super.fetchFromGitHub {
      owner = "chrjguill";
      repo = "i3lock-color";
      rev = "d03fbe70c92505627af61a1464f2eaafe9fcbfd5";
      sha256 = "12vw90n6pmz1fxqv55nlwpbfzj9wap6b7rcrxjgfl0snqx3nijlg";
    };
  });
  # spotify = overrideOlder pkgs.spotify (attrs: rec {
      # version = "1.0.48.103.g15edf1ec-94";
      # name = "spotify-${version}";
      # src = fetchurl {
      #   url = "http://repository-origin.spotify.com/pool/non-free/s/spotify-client/spotify-client_${version}_amd64.deb";
      #   sha256 = "0rpwxgxv2ihfhlri98k4n87ynlcp569gm9q6hd8jg0vd2jgji8b3";
      # };
  #});

  haskellPackages = with super.haskell.lib; super.haskellPackages.extend (self: super:{
    X11 = overrideCabal super.X11 (drv: {
      librarySystemDepends = drv.librarySystemDepends ++ [ pkgold.xorg.libXScrnSaver ];
    });
  });
}
