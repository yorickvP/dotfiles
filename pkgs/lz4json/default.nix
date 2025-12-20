{
  stdenv,
  fetchFromGitHub,
  lz4,
  pkg-config,
}:
stdenv.mkDerivation (o: {
  pname = "lz4json";
  version = "20191229";
  src = fetchFromGitHub {
    repo = o.pname;
    owner = "andikleen";
    rev = "c44c51005c505de2636cc1e59cde764490de7632";
    hash = "sha256-rLjJ7qy7Tx0htW1VxrfCCqVbC6jNCr9H2vdDAfosxCA=";
  };
  buildInputs = [ lz4 ];
  nativeBuildInputs = [ pkg-config ];
  installPhase = ''
    runHook preInstall
    install -D -t $out/bin lz4jsoncat
    runHook postInstall
  '';
})
