 let
   pkgs = import <nixpkgs> {};
   stdenv = pkgs.stdenv;
 in rec {
   luathing = stdenv.mkDerivation rec {
     name = "lua-dev";
     src = ./.;
     buildInputs = with pkgs.luaPackages; [ lua lgi ];
   };
 }
