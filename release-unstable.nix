let pkgs = import <nixpkgs> {config = import ./nix/.nixpkgs/config.nix;};
all_userspace = pkgs.lib.mapAttrs (name: paths: pkgs.buildEnv {inherit name paths;}) pkgs.hosts;
in
with pkgs;
{
	dotfiles = {
		inherit (import ./default.nix pkgs) ascanius jarvis;
	};
	userspace = {
		inherit (all_userspace) ascanius jarvis;
	};
}
