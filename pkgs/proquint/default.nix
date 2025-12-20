{ python3 }:
python3.pkgs.buildPythonPackage rec {
  pname = "proquint";
  version = "0.2.1";

  src = python3.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "0dda5h3lc4mv5sch1cvdjk4hvcng6nzabbpby2f7vvbf5x61mmij";
  };
  checkInputs = with python3.pkgs; [
    nose
    hypothesis
  ];
  pythonImportsCheck = [ "proquint" ];

  meta = {
    description = "Proquints: Identifiers that are Readable, Spellable, and Pronounceable";
    homepage = "https://pypi.org/project/proquint/";
  };
}
