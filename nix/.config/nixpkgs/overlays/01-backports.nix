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
  # numix-solarized-gtk-theme = super.numix-solarized-gtk-theme.overrideDerivation (attrs: rec {
  #   version = "20180204";
  #   name = "numix-solarized-gtk-theme-${version}";
  #   buildInputs = attrs.buildInputs ++ [ self.python3 self.inkscape ];
  #   src = self.fetchFromGitHub {
  #     owner = "Ferdi265";
  #     repo = "numix-solarized-gtk-theme";
  #     rev = "3da78b0dbe74d0af0e3cc12e18ec1c30c7cf2b16";
  #     sha256 = "0dyqfcs1laff7hr64dg4n5y6qrcki47mdr332yn3yxp3bk7xybc3";
  #   };
  #   postPatch = attrs.postPatch + ''
  #     sed -i s#/usr/bin/inkscape#${self.inkscape}/bin/inkscape# scripts/render-assets.sh
  #   '';
  #   buildPhase = ''
  #     # for i in Solarized*.colors; do
  #     #   THEME=`basename $i` make
  #     # done
  #   '';
  #   installPhase = ''
  #     for i in Solarized*.colors; do
  #       HOME=/tmp/inkscape make install THEME=`basename $i .colors`
  #     done
  #   '';
  # });
}
