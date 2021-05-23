{ stdenv, lib, fetchurl, makeDesktopItem
, jre, libX11, libXext, libXcursor, libXrandr, libXxf86vm
, mesa, openal, pulseaudioLight }:

let
lib_path = lib.concatMapStringsSep ":" (x: x.out + "/lib/") [libX11 libXext libXcursor libXrandr libXxf86vm mesa openal];
in
 stdenv.mkDerivation {
    name = "ftb-1.4.17";
    src = fetchurl {
        url = "http://ftb.cursecdn.com/FTB2/launcher/FTB_Launcher.jar";
        sha256 = "0c60nbddxs8mv6i7g5dz365sfjrdq9pk12xggk4bm4px7xg5gv7j";
    };

  phases = "installPhase";

  installPhase = ''
    set -x
    mkdir -pv $out/bin
    cp -v $src $out/ftblaunch.jar
    cat > $out/bin/feedthebeast << EOF
    #!${stdenv.shell}
    # wrapper for minecraft
    export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${lib_path}
    ${pulseaudioLight.out}/bin/padsp ${jre}/bin/java -jar $out/ftblaunch.jar
    EOF
    chmod +x $out/bin/feedthebeast
  '';

  meta = {
      description = "Modded minecraft launcher";
      homepage = http://www.feed-the-beast.com;
      license = stdenv.lib.licenses.unfreeRedistributable;
  };
}
