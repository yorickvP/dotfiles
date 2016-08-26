  let
    pkgs = import <nixpkgs> {};
    pypkg = pkgs.python27Packages;
  in
  { stdenv ? pkgs.stdenv, python27 ? pkgs.python27, fetchFromGitHub ? pkgs.fetchFromGitHub,
    virtualenv ? pypkg.virtualenv, lib ? pkgs.lib }:
  let
  inherit (lib) concatMapStringsSep mapAttrsToList concatStringsSep;
  deps = {
    # the script fetches two other repos from github
    pyrobase = fetchFromGitHub {
      owner = "pyroscope";
      repo = "pyrobase";
      rev = "b9253cb4a8a5781a859e3b1bc79d537d76abc326";
      sha256 = "0c2vjjb9bdrd2rx0cys3jzdwr5ljzsh14s18j5np6yg2vdcya35g";
    };
    auvyon = fetchFromGitHub {
      owner = "pyroscope";
      repo = "auvyon";
      rev = "5115c26f966df03df92a9934580b66c72e23d4e8";
      sha256 = "1qhig6xjv62gq4mj8rbhx6ifcffg321444j2fm6j8qk3yv8w5v4c";
    };
  };
  depnames = pkgs.lib.attrNames deps;
  outputscripts = ["chtor" "hashcheck" "lstor" "mktor" "pyroadmin" "pyrotorque" "rtcontrol" "rtevent" "rtmv" "rtxmlrpc"];
  in
  stdenv.mkDerivation {
    name = "pyroscope";
    version = "0.1.0.0";
    src = fetchFromGitHub {
      owner = "pyroscope";
      repo = "pyrocore";
      rev = "75393631130258d477adf3b4c77b2db085447383";
      sha256 = "02msqy40n41wzph75m5jiwphqj6wl2szp7izjwdlhrwfmr7cpamz";
    };
    buildInputs = [ python27 virtualenv ];
    patchPhase = ''
      patchShebangs src/scripts
    '';
    # make a virtualenv, install paver in it
    # XXX: impure :/
    buildPhase = ''
      virtualenv --never-download .
      bin/pip --no-cache-dir install "paver==1.2.4"
      bin/pip --no-cache-dir install "Tempita>=0.5.1"
      bin/pip --no-cache-dir install "APScheduler>=2.0.2,<3"
      bin/pip --no-cache-dir install "waitress>=0.8.2"
      bin/pip --no-cache-dir install "WebOb>=1.2.3"
    '' +
    (concatStringsSep "\n" (mapAttrsToList (depname: source:
      ''cp -R ${source} ./${depname}
      chmod -R +w ./${depname}
      (builtin cd ${depname} && ../bin/paver -q develop -U)
      '') deps)) +
    ''
      ./bin/paver -q develop -U
      ./bin/paver bootstrap
    '';
    # copy the neccesary parts of the virtualenv
    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/venv/{lib,bin,src}
      cp -R ./lib $out/venv/
      install ./bin/python2.7 $out/venv/bin
      cp -R src $out/venv/src/pyrocore
      ${concatMapStringsSep "\n" (x: ''
      cp -R ${x}/src $out/venv/src/${x}
      '') depnames}
      ${concatMapStringsSep "\n" (x: "install bin/${x} $out/bin/${x}") outputscripts}
    '';
    # patch the bin interpreter into the virtualenv and fix the internal .egg-links
    fixupPhase =
      (concatMapStringsSep "\n" (x: ''
        echo -e "$out/venv/src/${x}\n../" > $out/venv/lib/python2.7/site-packages/${x}.egg-link
      '') (depnames ++ ["pyrocore"])) + ''
      sed -i -e "1 s|.*|#\!$out/venv/bin/python2.7|" $out/bin/*
    '';
    dontPatchShebangs = true;

  }
