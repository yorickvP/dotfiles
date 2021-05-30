{ stdenv, callPackage }:

stdenv.mkDerivation {
  name = "yori-cc-1.5";

  src = builtins.fetchGit {
    url = "git@git.yori.cc:yorick/yori-cc.git";
    rev = "68c75ab84cceaf98dd8fd0646b97d73f966b8962";
  };

  buildInputs = [ ];

  installPhase = ''
    mkdir -p "$out/web"
    cp -ra * "$out/web"
  '';

  meta = {
    description = "Yori-cc website";
    homepage = "https://yorickvanpelt.nl";
    maintainers = [ "Yorick" ];
  };
}
