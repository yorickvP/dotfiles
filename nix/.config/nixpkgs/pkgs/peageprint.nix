{ pkgs ? import <nixpkgs> {}
, stdenv ? pkgs.stdenv
, fetchgit ? pkgs.fetchgit
, samba3_light ? pkgs.samba3_light
, lib ? pkgs.lib
}:
stdenv.mkDerivation {
  name = "peage-print";
  version = "0.1.2";
  src = fetchgit {
    url = https://gist.github.com/dsprenkels/d75d6856ec536a4b28422dd1aa107f9d;
    rev = "f18f2cbfc93ff475943abb414c84a51a597f48c5";
    sha256 = "019ggsn445sw8lb7gvwfsaxdkqdgf8dr5qb2ncir7akm7d70jnd7";
  };

  buildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    install ./peage-print $out/bin
    wrapProgram $out/bin/peage-print --suffix PATH : ${samba3_light}/bin
  '';
}
