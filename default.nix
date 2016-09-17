{pkgs ? import <nixpkgs> {}}:

let
inherit (pkgs) lib;
bin = pkgs.callPackage ./bin/default.nix {};
i3 = with_lock: pkgs.callPackage ./i3/i3.nix {
	inherit (bin) brightness screenshot_public;
	inherit with_lock;
};
in lib.mapAttrs (k: paths:
	pkgs.symlinkJoin { inherit paths; name = "dotfiles-${k}"; }
) {
	ascanius = [(i3 true)];
	woodhouse = [(i3 false)];
	pennyworth = [];
	frumar = [];
}
