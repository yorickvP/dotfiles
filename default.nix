{pkgs ? import <nixpkgs> {}}:

let
bin = pkgs.callPackage ./bin/default.nix {};
i3 = pkgs.callPackage ./i3/i3.nix {inherit (bin) brightness screenshot_public;};
in
{
	ascanius = pkgs.symlinkJoin { paths = [i3]; name = "dotfiles-ascanius"; };
	woodhouse = [];
	pennyworth = [];
	frumar = [];
}
