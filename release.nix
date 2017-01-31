let pkgs = import <nixpkgs> {config = import ./nix/.nixpkgs/config.nix;};
in
with pkgs;
{
	dotfiles = import ./default.nix pkgs;
	userspace = pkgs.lib.mapAttrs (name: paths: pkgs.buildEnv {inherit name paths;}) pkgs.hosts;
}
