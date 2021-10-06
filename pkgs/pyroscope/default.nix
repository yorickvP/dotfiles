{ fetchurl, fetchFromGitHub, python2 }:
let
  python2Packages = (python2.override {
    packageOverrides = self: super: {
      platformdirs = with self; (super.buildPythonPackage rec {
        pname = "platformdirs";
        version = "2.0.2";
        src = fetchFromGitHub {
          owner = pname;
          repo = pname;
          rev = version;
          sha256 = "04gjhd6msdbqq8xm7x2vwlgldrxvvrvi86yq7g81dxlpzcwdyay8";
        };
        SETUPTOOLS_SCM_PRETEND_VERSION = version;
        nativeBuildInputs = [ setuptools-scm ];
        doCheck = false;
      });
	    ProxyTypes = super.buildPythonPackage rec {
	      pname = "ProxyTypes";
        version = "0.10.0";
        src = self.fetchPypi {
          inherit pname version;
	        sha256 = "11cr6c39vq9fky4c4h2ai2v2dva8fk4cfhaja0mrh4y9wzal3k42";
        };
	    };
	    pyrobase = super.buildPythonApplication rec {
        pname = "pyrobase";
        version = "0.5.2";
	      src = fetchFromGitHub {
  	      repo = pname; owner = "pyroscope";
          rev = "v${version}";
  	      sha256 = "170lsls3dmhlfa5abk40l365pk8486w48vkxjgs3pnqnhpp67z18";
	      };
	      doCheck = false;
	      buildInputs = with self;[six paver];
	    };
    };
  }).pkgs;
in
with python2Packages;
buildPythonApplication rec {
  pname = "pyrocore";
  version = "0.5.3";
  src = fetchFromGitHub {
  	repo = pname; owner = "pyroscope";
    rev = "v${version}";
  	sha256 = "0yg11nhrx8jzx8g09npf0pcpiscyh35nahhw473mir418plji5jw";
  };
  doCheck = false; # hmm
  buildInputs = [paver];
  propagatedBuildInputs = [six pyrobase ProxyTypes setuptools];
}
