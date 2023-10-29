{
  inputs = {
    dream2nix.url = "github:yorickvP/dream2nix";
    #dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.follows = "dream2nix/nixpkgs";
  };
  outputs = { self, dream2nix, nixpkgs }:
    let
      nixpkgs' = import nixpkgs {
        config.allowUnfree = true;
        system = "x86_64-linux";
      };
      package = dream2nix.lib.evalModules {
        modules = [ {
          paths.projectRoot = ./.;
          paths.projectRootFile = "flake.nix";
          paths.package = ".";
        } ./package.nix ];
        packageSets.nixpkgs = nixpkgs';
      };
    in {
      packages.x86_64-linux.default = package;
      devShells.x86_64-linux.default = package.devShell;
      packages.x86_64-linux.lock = package.config.lock.refresh;
    };
}
