{ stdenv, python3, fetchFromGitHub, makeWrapper }:
let
  python = python3.withPackages (p: [ p.paho-mqtt p.libscrc ]);
in
stdenv.mkDerivation (o: {
  pname = "grott";
  version = "2.7.8";
  src = fetchFromGitHub {
    owner = "johanmeijer";
    repo = o.pname;
    rev = "cb7e3db8a9ea2ab11fad062d68a3e98e6a87cedf";
    sha256 = "rFxSQZypa+G45jj/ktJLlqfMIp1yHoEmfzB1BvHLeLo=";
  };
  nativeBuildInputs = [ makeWrapper ];
  buildPhase = "true";
  installPhase = ''
    mkdir -p $out/share/grott
    cp *.py examples/recwl.txt examples/Home\ Assistent/grott_ha.py $out/share/grott/
    makeWrapper ${python}/bin/python3 $out/bin/grott \
      --add-flags $out/share/grott/grott.py
  '';
  meta = with stdenv.lib; {
    description = "Grott is a program to read data from a Growatt inverter and send it to a MQTT broker";
    homepage = o.src.homePage;
  };
})
