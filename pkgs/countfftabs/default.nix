{
  stdenv, simdjson, lz4
}:
stdenv.mkDerivation {
  name = "countfftabs";
  src = ./.;
  buildInputs = [simdjson lz4];
  buildPhase = ''
    runHook preBuild
    g++ -o ./countfftabs count.cpp -I${simdjson}/include -L${simdjson}/lib -lsimdjson -llz4
    runHook postBuild
  '';
  installPhase = "mkdir -p $out/bin; mv ./countfftabs $out/bin/";
}
