{ pkgs ? import <nixpkgs> {} }:
#{ writeScript ? pkgs.writeScript, lib ? pkgs.lib, stdenv ? pkgs.stdenv }:
with pkgs;
let
  compileShell = src: buildInputs: name: stdenv.mkDerivation {
    inherit name src;
    buildInputs = buildInputs ++ [makeWrapper];
    unpackPhase = "true";
    installPhase = ''mkdir -p $out/bin && cp $src $out/bin/${name}
      wrapProgram $out/bin/${name} --suffix PATH : ${lib.makeSearchPath "bin" buildInputs}
    '';
  };
in lib.mapAttrs (k: f: f k) {
  backup = compileShell ./backup.sh
    (with pkgs; [utillinux duplicity]);
  screenshot_public = compileShell ./screenshot_public.sh
    (with pkgs; [scrot xclip rsync]);
}
