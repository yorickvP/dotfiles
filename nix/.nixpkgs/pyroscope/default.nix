let pkgs = import <nixpkgs> {};
in
{ fetchurl ? pkgs.fetchurl,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  python27Packages ? pkgs.python27Packages }:

with python27Packages;
let
	ProxyTypes = buildPythonPackage rec {
	  name = "ProxyTypes-0.9";
	  src = pkgs.fetchurl {
		url = "https://pypi.python.org/packages/72/bd/24f45710e7e6909b2129332363be2c981179ed2eda1166f18bc2baef98a1/${name}.zip";
	    sha256 = "03zfq1ib23dc9rq759n43ri2ki6841yjisdcb59jvp5dqww5bcr0";
	  };

	};
	pyrobase = buildPythonApplication rec {
	  name = "pyrobase-0.3";
	  src = fetchFromGitHub {
	  	repo = "pyrobase"; owner = "pyroscope";
	  	rev = "cf64da5d89df1c1174e0184c63a51a46f2f955fd";
	  	sha256 = "12qn1gx64byi76kkx8p7y5gdrq016fw2s23l4yik0q1hdg2b99y8";
	  };
	  patches = [./fix_readme.diff];
	  buildInputs = [paver];
	};

in
buildPythonApplication rec {
  name = "pyrocore-0.4.3";
  src = fetchFromGitHub {
  	repo = "pyrocore"; owner = "pyroscope";
  	rev = "a8d81af33959333a42a95714631c69870b717329";
  	sha256 = "1fvahnkhh4nj7qy9m4j2c0djmf4ichy29s7b9wkn7ivhlcgv9hs0";
  };
  doCheck = false;
  buildInputs = [python27Packages.paver];
  propagatedBuildInputs = [pyrobase ProxyTypes];
}
