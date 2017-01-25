{ pkgs ? import <nixpkgs> {},
  stdenv ? pkgs.stdenv,
  love_0_7 ? pkgs.love_0_7 }:
  let
  	name = "nottetris2";
	src = pkgs.fetchzip {
		url = "http://stabyourself.net/dl.php?file=${name}/${name}-linux.zip";
		sha256 = "1zwwp4h1njwl3jnwkszcsqx868v16312pbfy5rp9h48ym79spd36";
		stripRoot = false;
	};
in
  pkgs.writeScriptBin name ''
  	#! ${stdenv.shell} -e
  	exec ${love_0_7}/bin/love "${src}/Not Tetris 2.love"
  ''
