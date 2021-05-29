let sources = import ./nix/sources.nix;
in pkgs: super: {
  yorick = super.yorick // rec {
    home = { check ? true, newsReadIdsFile ? null }:
      import "${sources.home-manager}/home-manager/home-manager.nix" {
        confPath = ./nix/.config/nixpkgs/home.nix;
        inherit pkgs check newsReadIdsFile;
      };
  };
}
