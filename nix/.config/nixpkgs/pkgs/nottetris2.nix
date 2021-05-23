{ pkgs ? import <nixpkgs> { }, stdenv ? pkgs.stdenv, love_0_7 ? pkgs.love_0_7 }:
# let
#   name = "nottetris2";
#   src = pkgs.fetchzip {
#     url = "http://stabyourself.net/dl.php?file=${name}/${name}-linux.zip";
#     sha256 = "1zwwp4h1njwl3jnwkszcsqx868v16312pbfy5rp9h48ym79spd36";
#     stripRoot = false;
#   };
# in pkgs.writeShellScriptBin name ''
#   exec ${love_0_7}/bin/love "${src}/Not Tetris 2.love"
# ''
  stdenv.mkDerivation {
    pname = "nottetris";
    version = "2";
    buildInputs = [ love_0_7 pkgs.unzip pkgs.makeWrapper ];
    nativeBuildInputs = [ pkgs.unzip ];
    src = pkgs.fetchurl {
      url = "https://stabyourself.net/dl.php?file=nottetris2/nottetris2-source.zip";
      sha256 = "13lsacp3bd1xf80yrj7r8dgs15m7kxalqa7vml0k7frmhbkb0b1n";
    };
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/lib
      cp "Not Tetris 2.love" $out/lib/
      makeWrapper $(command -v love) $out/bin/nottetris2 --add-flags "\"$out/lib/Not Tetris 2.love\""
    '';
    # meta = {
    #   license = 
    # };
  }
