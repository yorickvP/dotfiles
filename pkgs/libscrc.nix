{ lib, buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "libscrc";
  version = "1.8.1";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-17pr8jz96ztynQrTeV9sb5fY6kFVJS48qfFHWHArp8g=";
  };

  propagatedBuildInputs = [];

  pythonImportsCheck = [ "libscrc" ];

  meta = with lib; {
    description = "A library for calculating CRC, CRC-ITU, CRC-32, CRC-16, CRC-CCITT";
    homepage = "https://github.com/hex-in/libscrc";
    license = licenses.mit;
    maintainers = with maintainers; [ yorickvp ];
  };
}
