{ jdk7, ant, libusb, makeWrapper, stdenv, lib, fetchurl }:
let lejospkg = type: attrs:
    stdenv.mkDerivation ({
    name = "lejos-${type}-${attrs.version}";
    JDK_PATH = jdk7;
    buildPhase = ''
        pushd build
        ant
        popd
    '';
    installPhase = ''
        runHook preInstall
        mkdir -p $out/opt/lejos/${type} $out/bin
        cp -r * $out/opt/lejos/${type}
        for i in $(find $out/opt/lejos/${type}/bin/* -executable); do
            makeWrapper $i $out/bin/`basename $i` --set JAVA_HOME $JDK_PATH \
            --set ${lib.toUpper type}_HOME $out/opt/lejos/${type}
        done
        runHook postInstall
    '';
    buildInputs = [ jdk7 ant libusb makeWrapper ];
} // attrs);
in
{

  nxj = lejospkg "nxj" rec {
    version = "0.9.1beta-3";
    src = fetchurl { 
  	  url  = "mirror://sourceforge/nxt.lejos.p/${version}/leJOS_NXJ_${version}.tar.gz";
  	  sha256 = "18ll9phbl1i2dasici1m8jprcfhzl03dq0h1dsdl9iwq1yv380pi";
    };
  };
  ev3 = lejospkg "ev3" rec {
    version = "0.9.1-beta";
    src = fetchurl {
  	  url  = "mirror://sourceforge/ev3.lejos.p/${version}/leJOS_EV3_${version}.tar.gz";
  	  sha256 = "12v5za15xijq8frsvrf1amr75jf80c593xdpplcx5l4rxhb3bprp";
    };
    buildPhase = "echo binary distribution";
    postPatch = ''
      mkdir -p $out/share/java
      cp $(find . -iname '*.jar') $out/share/java
    '';
  };
}
