let pkgs = import <nixpkgs> {config = import ./nix/.nixpkgs/config.nix;};
in
with pkgs;
{
	dotfiles = with (import ./default.nix pkgs); [ascanius jarvis];
	userspace = with (pkgs.lib.mapAttrs (name: paths: pkgs.buildEnv {inherit name paths;}) pkgs.hosts); [ascanius jarvis];
}
