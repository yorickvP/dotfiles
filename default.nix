{pkgs ? import <nixpkgs> {}}:

let
inherit (pkgs) lib;
bin = pkgs.callPackage ./bin/default.nix {};
i3 = with_lock: pkgs.callPackage ./i3/i3.nix {
	inherit (bin) screenshot_public;
	inherit with_lock;
};
xres = dpi: pkgs.callPackage ./x/default.nix { inherit dpi; };
in lib.mapAttrs (k: paths:
	pkgs.symlinkJoin { inherit paths; name = "dotfiles-${k}"; }
) {
	ascanius = [(i3 true) (xres 109)];
	woodhouse = [(i3 false) (xres 44)];
	pennyworth = [];
	frumar = [];
	jarvis = [(i3 true) (xres 192)];
}
