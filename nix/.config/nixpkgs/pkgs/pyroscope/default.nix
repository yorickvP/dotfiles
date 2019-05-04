{ fetchurl, fetchFromGitHub, python2Packages }:
with python2Packages;
let
	ProxyTypes = buildPythonPackage rec {
	  pname = "ProxyTypes";
    version = "0.10.0";
    src = fetchPypi {
      inherit pname version;
	    sha256 = "11cr6c39vq9fky4c4h2ai2v2dva8fk4cfhaja0mrh4y9wzal3k42";
    };
	};
	pyrobase = buildPythonApplication rec {
    pname = "pyrobase";
    version = "0.5.2";
	  src = fetchFromGitHub {
  	  repo = pname; owner = "pyroscope";
      rev = "v${version}";
  	  sha256 = "170lsls3dmhlfa5abk40l365pk8486w48vkxjgs3pnqnhpp67z18";
	  };
	  doCheck = false;
	  buildInputs = [six paver];
	};

in
buildPythonApplication rec {
  pname = "pyrocore";
  version = "0.5.3";
  src = fetchFromGitHub {
  	repo = pname; owner = "pyroscope";
    rev = "v${version}";
  	sha256 = "0yg11nhrx8jzx8g09npf0pcpiscyh35nahhw473mir418plji5jw";
  };
  buildInputs = [paver];
  propagatedBuildInputs = [six pyrobase ProxyTypes];
}
