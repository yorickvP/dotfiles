{
  pkgs ? import <nixpkgs> { },
}:
#{ writeScript ? pkgs.writeScript, lib ? pkgs.lib, stdenv ? pkgs.stdenv }:
with pkgs;
let
  compileShell =
    src: buildInputs: name:
    stdenv.mkDerivation {
      inherit name src;
      buildInputs = buildInputs ++ [ makeWrapper ];
      nativeBuildInputs = [ shellcheck-minimal ];
      unpackPhase = "true";
      buildPhase = ''
        shellcheck $src
      '';
      installPhase = ''
        mkdir -p $out/bin && cp $src $out/bin/${name}
        wrapProgram $out/bin/${name} --suffix PATH : ${lib.makeSearchPath "bin" buildInputs}
      '';
    };
  makeWrap =
    cmd: executable: name:
    pkgs.runCommand name { buildInputs = [ makeWrapper ]; } ''
      makeWrapper ${executable} $out/bin/${name} --add-flags ${cmd}
    '';
in
lib.mapAttrs (k: f: f k) {
  backup = compileShell ./backup.sh (
    with pkgs;
    [
      util-linux
      duplicity
    ]
  );
  screenshot_public = compileShell ./screenshot_public.sh (
    with pkgs;
    [
      scrot
      xclip
      rsync
    ]
  );
  # Using uv2nix with PEP-723 inline metadata
  y-cal-widget = _: lib.loadUvScript ./y-cal-widget.py;
  absorb = _: lib.loadUvScript ./absorb.py;
  backup-laptop = compileShell ./backup-laptop [ ];
}
