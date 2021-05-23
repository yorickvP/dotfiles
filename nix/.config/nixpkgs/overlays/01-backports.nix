self: super:
let
  overrideOlder = original: override: with self.lib; let
  newpkgver = getVersion (override original);
  oldpkgver = getVersion original;
    in if (versionOlder oldpkgver newpkgver) then original.overrideDerivation override else original;
in
{
  factorio = super.factorio.override {
    releaseType = "alpha";
    username = "yorickvp";
    token = "dd8dca57e4f1891117d351b25cf56f";
  };
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
