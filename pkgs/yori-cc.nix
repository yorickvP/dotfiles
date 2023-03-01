{ stdenv, callPackage }:

stdenv.mkDerivation {
  name = "yori-cc-1.5";

  src = builtins.fetchGit {
    url = "git@git.yori.cc:yorick/yori-cc.git";
    rev = "4e3a1e9f4a5171b4c2fd54b03c9047536d5a0214";
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
