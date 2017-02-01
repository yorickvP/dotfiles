let pkgs = import <nixpkgs> {config = import ./nix/.nixpkgs/config.nix;};
all_userspace = pkgs.lib.mapAttrs (name: paths: pkgs.buildEnv {inherit name paths;}) pkgs.hosts;
in
with pkgs;
{
	dotfiles = {
		inherit (import ./default.nix pkgs) woodhouse pennyworth frumar;
	};
	userspace = {
		inherit (all_userspace) woodhouse pennyworth frumar;
	};
}
